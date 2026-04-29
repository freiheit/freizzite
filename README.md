# freizzite

[![Build container image](https://github.com/freiheit/freizzite/actions/workflows/build.yml/badge.svg)](https://github.com/freiheit/freizzite/actions/workflows/build.yml)
[![pre-commit checks](https://github.com/freiheit/freizzite/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/freiheit/freizzite/actions/workflows/pre-commit.yml)

This is a freiheit clone of
[bazzite](https://github.com/ublue-os/bazzite)
using <https://github.com/ublue-os/image-template> to start with.

Go look at those 2 places for useful info/links, etc.

## Variants

| Variant               | Description                               |
| --------------------- | ------------------------------------------|
| freizzite             | KDE Desktop/Laptop with AMD/Intel/etc GPU |
| freizzite-nvidia-open | KDE Desktop/Laptop with Nvidia GPU        |
| freizzite-deck        | KDE SteamDeck or similar                  |

## Installation

0. **Don't**; you'd have to be crazy to do that
1. Install bazzite (or another ublue flavor)
2. Run `sudo bootc status` and `sudo rpm-ostree status` and save the info somewhere.
3. Optional: `sudo ostree admin pin 0`
4. Depending which flavor you want, one of these:
   * `sudo bootc switch --enforce-container-sigpolicy ghcr.io/freiheit/freizzite`
   * `sudo bootc switch --enforce-container-sigpolicy ghcr.io/freiheit/freizzite-nvidia-open`
   * `sudo bootc switch --enforce-container-sigpolicy ghcr.io/freiheit/freizzite-deck`
5. reboot

... maybe that's supposed to be an `rpm-ostree rebase` instead?

### ISOs (available on request; untested)

**Untested** ISOs available on request.

Generating them isn't a problem, but hosting downloads for 7-10GB files is
potentially pricey.

## Recovery

If you want to swap back.

* Temporary: reboot and pick the previous version
* Permanent: `sudo bootc switch ghcr.io/ublue-os/bazzite-something`
  (Refer to saved `rpm-ostree status` info from install)
