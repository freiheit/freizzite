# freizzite

[![Build container image](https://github.com/freiheit/freizzite/actions/workflows/build.yml/badge.svg)](https://github.com/freiheit/freizzite/actions/workflows/build.yml)
[![Build disk images](https://github.com/freiheit/freizzite/actions/workflows/build-disk.yml/badge.svg)](https://github.com/freiheit/freizzite/actions/workflows/build-disk.yml)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/freizzite)](https://artifacthub.io/packages/search?repo=freizzite)
[![Dependabot Updates](https://github.com/freiheit/freizzite/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/freiheit/freizzite/actions/workflows/dependabot/dependabot-updates)

This is a freiheit clone of 
[bazzite](https://github.com/ublue-os/bazzite)
using https://github.com/ublue-os/image-template to start with.

Go look at those 2 places for useful info/links, etc.

## Installation

0. **Don't**; you'd have to be crazy to do that
1. Install bazzite (or another ublue flavor)
2. Run `sudo bootc status` and `sudo rpm-ostree status` and save the info somewhere.
3. Optional: `sudo ostree admin pin 0`
4. Depending which flavor you want, one of these:
   * `sudo bootc switch ghcr.io/freiheit/freizzite`
   * `sudo bootc switch ghcr.io/freiheit/freizzite-nvidia-open`
   * `sudo bootc switch ghcr.io/freiheit/freizzite-deck`
5. reboot

... maybe that's supposed to be an `rpm-ostree rebase` instead?

### Recovery

If you want to swap back.

* Temporary: reboot and pick the previous version
* Permanent: `sudo bootc switch ghcr.io/ublue-os/bazzite-something` (Refer to saved `rpm-ostree status` info from install)

