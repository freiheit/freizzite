# freizzite roadmap

Working list of fork-specific ideas and follow-ups. Fork-only file (upstream
image-template has none). Keep entries short; move deep detail into PRs.

Legend: **[ ]** todo · **[~]** in progress · **[x]** done · **(?)** needs a decision

Convention: active work is ordered top→bottom (top = next). Items that are
finished but not yet validated sit under "Pending validation." Once validated,
move them to "Done" at the very bottom.

---

## Active work (top = next)

### ISO hosting → B2 + Fastly [ ]

GitHub Releases can't host the ISOs: **2 GiB/file** cap vs 7–10 GB ISOs.
**Decision:** Backblaze B2 (already have) + **Fastly**. B2's Bandwidth Alliance
gives free egress to Fastly, so only cheap B2 storage remains — and Fastly is
Eric's wheelhouse. Possible bonus: Fastly Fast Forward (free CDN for OSS) —
verify eligibility. **Next:** design upload + Fastly service (origin = B2
bucket, cache, TLS, custom domain). Ties into releases below.

### Releases + ISO automation [~]

**Done 2026-10-10:** `release.yml` + `.github/scripts/release-gate.sh` cut a
GitHub Release after any successful build once every stable image carries the
newest stable bazzite release's commit (`org.opencontainers.image.revision`,
inherited from the pinned base) and that tag has no release here yet. Tag =
upstream tag on the main tip (GITHUB_TOKEN cannot tag an older commit whose
workflow files differ), notes = upstream link + the images' source commit +
pinned image refs + GitHub generated notes since the previous release. No
SBOM package diff: bazzite's `changelog.py` needs SBOMs we do not attach.
**Still open:** build ISOs → upload to B2 → add hosted ISO URLs to the notes.

### Small follow-ups [ ]

- **Pin the chunkah image digest.** `Justfile` `rechunk` pulls
  `quay.io/coreos/chunkah:latest` (TODO in the recipe). Pin to a digest and
  let renovate bump it once the tool is stable enough to trust blind.
- **Deck login-manager link check.** `build_files/build.sh` skips the runtime
  linkage check for bazzite-deck because the SDDM binary paths are
  unconfirmed. Confirm them against the bazzite-deck image and add them.

### Upstream survey — remaining candidates (reference)

From scanning `ublue-os/main` + `ublue-os/bazzite` (workflows/Justfiles only):

- **just syntax check:** bazzite `just-syntax-check.yml` (`ublue-os/just-action`)
  on PRs. Likely redundant — `build.yml` already runs `just check` on PRs.
- **Handy Justfile recipes (optional):** `list-images`, `clean-images`,
  `clean-isos` (bazzite); `verify-container` (main). Small local-dev niceties;
  each is divergence — adopt only on clear need.
- **Emergency retag (low value):** bazzite `retag.yml` (manual, "never
  automate"). Only if a bad publish needs rolling back by tag.

## Deferred

- **Seeded rechunk:** `ostree-rechunk-seeded` in the `Justfile` is unused since
  2026-10-10 because `rpm-ostree compose build-chunked-oci` panics with a
  baseline image (bootc-dev/bootc#1885). The unseeded variant builds but drops
  the image config (no labels), so CI uses chunkah. Revisit when the upstream
  bug closes; drop both rpm-ostree recipes if chunkah holds for a few months.

## Pending validation (watch; act only if they fail)

- _(nothing pending)_

## Done (validated)

- **Chunkah rechunk (2026-10-10):** first main build green on all three
  targets; published images carry `io.github.freiheit.build.*` and
  `org.opencontainers.image.revision` again, 128 layers each.
- **testing-tag builds (2026-10-10):** `build.yml` probes
  `ghcr.io/ublue-os/<base>:testing` in a preflight `matrix` job and adds a
  `testing` stream per variant when it exists. Testing publishes only
  `testing`-prefixed tags; `clean.yml` excludes `testing`. `freizzite-deck:testing`
  publishes from the bazzite testing base with its own revision label.
- **ubuntu-26.04 runners (2026-10-10):** `build_push` and `build-disk.yml` both
  run on 26.04 after the 24.04 disk-pressure hangs (two one-line `RUN`s took
  ~30 min each, rpmdb corrupted during rechunk). 26.04 ignores `sudo -E`, which
  once published deck tags built from the dx-nvidia base; matrix values now go
  through `sudo env …` and an assertion checks the built image's
  `io.github.freiheit.build.base-ref` label. The mislabeled 2026-08-15 tags were
  pruned by `clean.yml`. `container-storage-action` stays as inert insurance
  (only acts on the 72G runner pool).
- **os-release branding (2026-10-10):** `build_files/image-info` sets `NAME`,
  `PRETTY_NAME`, `VARIANT`, `DEFAULT_HOSTNAME`, `HOME_URL`, `BUG_REPORT_URL`,
  `BOOTLOADER_NAME` and `/etc/system-release`; `ID`, `VARIANT_ID`, `CPE_NAME`
  and friends keep upstream values on purpose. Verified on a deployed
  dx-nvidia machine: `hostnamectl` says Freizzite and the boot entries are
  titled Freizzite. Same change in freirora.
- **Artifact Hub listings (2026-10-10):** both `freizzite-deck` and
  `freizzite-dx-nvidia` show `verified_publisher: true`.
- **Old-image cleanup (2026-10-10):** `clean.yml` has run weekly since
  2026-08-16 without a failure (older-than 30 days, keep 10 tagged, 3 untagged).
- **README badges (2026-10-10):** all seven render, including the CodeQL
  default-setup badge.
- **CodeQL (2026-10-10):** default setup with `actions` + `python` now passes
  on every push, so the earlier "no Python in repo" error is gone. Nothing to
  change.
- **Per-variant `IMAGE_DESC`:** `image_desc` field in the `build.yml` matrix,
  exported as `IMAGE_DESC` in the `build_push` env. Local builds keep the
  `image-template.env` default.
