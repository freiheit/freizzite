# Baking OpenVox into freizzite

Work item for the `freizzite` repo (base: `bazzite-dx-nvidia`). Companion to
the `openvox-control` repo, which expects the agent to already exist on
`monolith` and `decky`.

## Status (2026-09-07): implemented, build+VM verification pending

- Install lives in `build_files/build-common.sh` (both variants); repo file in
  `system_files/etc/yum.repos.d/openvox.repo` with `gpgcheck=1` (packages are
  signed, key `5fb999c2d62ff3d9`). Not a hard pin: the build probes the
  current Fedora release's repo and falls back one release on a definite 404
  (same idiom as the terra fallback in build.sh), so an F45 image builds
  against fedora/44 until OpenVox publishes fedora/45, then picks it up
  automatically.
- **The relocation below is NOT needed.** freizzite's own Containerfile already
  un-symlinks `/opt` into a real image directory, so `/opt/puppetlabs` ships in
  the image and updates with it. Confirmed on `monolith`: `/opt` is a real dir.
- g10k moved to the voxpupuli org: asset is
  `g10k_0.10.0_linux_amd64.tar.gz`, sha256 pinned in build-common.sh.
- The openvox9 fedora/44 repo currently carries only `9.0.0~rc1` for
  openvox-agent (openvox8 has stable 8.29.0). Staying on 9 per this doc;
  revisit if rc1 misbehaves.
- `puppet --version` and `g10k -version` run at build time, so "does the fc44
  AIO execute on this Fedora release" is now checked on every build.
- Still open: the VM boot / rebase / `apply.sh --noop` steps under
  "Verify before trusting".

## Goal

`openvox-agent` and `g10k` present in the image, at paths that survive image
upgrades, with `vardir` on a writable filesystem.

## Hard constraint

**An OpenVox packaging lag must never block a freizzite rebuild.** OpenVox
shipped Fedora 44 packages roughly six weeks after Fedora 44 GA, and Fedora 45
GA is targeted for 2026-10-20. A Containerfile that installs from
`openvox9/fedora/$releasever` would stall the image every October.

The fix is a probe with one-release fallback (see Status above); the original
plan was a hard pin to fedora/44:

```text
https://yum.voxpupuli.org/openvox9/fedora/44/$basearch
```

Running one release behind is safe because the AIO package is self-contained. Verified from repodata
and ELF inspection:

- RPM builds with `Autoprov: 0` / `Autoreq: 0`; the only explicit requires are
  `/bin/sh`, `findutils`, `systemd`, `tar`.
- The vendored Ruby links only `libz.so.1`, `libcrypt.so.2`, `libgcc_s.so.1`,
  `libm`, `libc`, plus `libselinux.so.1` for the SELinux extension. OpenSSL,
  libyaml, libffi, libaugeas and libxml2 are all vendored.
- The `fc44` in the filename comes from `%{?dist}` and nothing else.

Installing on a newer Fedora is verified at the dependency level, not executed.
Confirm on first build.

## The trap worth knowing about

Aurora and Bluefin end their builds with:

```sh
rm -rf /opt && ln -s /var/opt /opt
```

and bootc treats image content under `/var` like a Docker `VOLUME`: it is
unpacked **only from the initial image** and never refreshed on later pulls.
So `dnf install openvox-agent` in a derived Containerfile drops the agent into
`/var/opt/puppetlabs`, where it is seeded once and then frozen. Updating the
agent in a future image would silently do nothing on machines already deployed.

`bazzite-dx` ships the counter-pattern in `build_files/50-fix-opt.sh`: relocate
into `/usr/lib/opt` and put a tmpfiles symlink back.

**Check first** whether your `bazzite-dx-nvidia` base already applies
`50-fix-opt.sh`, or whether it inherits the raw Aurora/Bluefin symlink. That
determines whether the relocation below is needed or redundant.

## Containerfile sketch

Not tested. Treat as a starting point, not a recipe.

Superseded by the real implementation in `build_files/build-common.sh` (which
skips the `/usr/lib/opt` relocation entirely -- see Status above) and the
pinned repo file in `system_files/etc/yum.repos.d/openvox.repo`. The sketch
also guessed the g10k asset name; the real one is
`g10k_<ver>_linux_amd64.tar.gz` under the voxpupuli org, checksum-verified in
the build script.

The `server = localhost` line is deliberate: OpenVox 9 raises `ArgumentError`
when running as root with `server` unset. `puppet apply` most likely never
reaches that code path, but the line costs nothing.

Do **not** enable `puppet.service`. This is a masterless fleet;
`profile::base` masks it.

## Do not use the gem instead

`gem install openvox` sidesteps Fedora-release packaging entirely, and is the
wrong trade. The AIO bundles nine core modules the gem does not:
`augeas_core`, `cron_core`, `host_core`, `mount_core`, `scheduled_task`,
`selinux_core`, `sshkeys_core`, `yumrepo_core`, `zfs_core`. Losing `yumrepo`,
`cron`, `mount`, `host` and `ssh_authorized_key` as native types is not worth
avoiding a pinned repo URL. The gem also drops the native `ruby-selinux` and
`ruby-shadow` bindings, degrading SELinux contexts and user password
management.

## Verify before trusting

1. Build, boot in a VM, and confirm `/opt/puppetlabs` resolves and
   `/opt/puppetlabs/bin/puppet --version` runs.
2. Rebase the VM to a newer image and confirm the agent version actually moves.
   That is the whole point of the `/usr/lib/opt` relocation and the only way to
   know it worked.
3. Run `/var/lib/openvox-control/scripts/apply.sh --noop` and confirm a catalog
   compiles with no write attempts under `/usr` or `/opt`.
4. Only then do the same on `decky`.

## Open questions (answered 2026-09-07)

- ~~Whether `bazzite-dx-nvidia` already carries the `50-fix-opt.sh`
  relocation.~~ Moot: freizzite's own Containerfile makes `/opt` a real image
  directory before any package lands, so the agent ships in the image proper.
- Whether the fc44 RPM actually runs on an fc45 host. Dependency evidence says
  yes; `puppet --version` now executes on every build, so the first fc45-based
  build answers this automatically (red build if not).
- ~~Whether `/opt` on your specific base is a real directory or the `/var/opt`
  symlink.~~ Real directory, confirmed on `monolith`.
