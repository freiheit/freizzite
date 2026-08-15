# Freizzite logo

`freizzite-logo.svg` is the master, and the only file here to edit by hand.
Everything else in this directory is generated from it.

Regenerate after editing:

```sh
just freizzite-logo
```

## Generated here

- `freizzite-logo-head.svg` — head only, no torso
- `freizzite-logo-head-short.svg` — head with the antennae pulled in
- `freizzite-logo-kde.svg` — full robot, lightened, with a white keyline
- `png/<name>-2048.png` … `png/<name>-32.png` — every svg above, longest side in pixels
- `png/freizzite-logo-banner-1280x640.png` — cropped head, for a social preview

## Generated elsewhere

- `system_files/…/hicolor/scalable/apps/freizzite-logo-icon.svg` — os-release `LOGO=`
- `system_files/…/hicolor/scalable/distributor-logo.svg` — KDE launcher
- `system_files/…/ublue-os/freizzite/logo.txt` — the fastfetch logo

## Editing notes

- Element `id`s are load-bearing: `render.py` locates geometry by them.
- Everything except `#mouth` mirrors about the centre of `#head`, at x=250.
- The antennae sit behind `#head` so their round line caps stay hidden.
- The keyline is applied to the silhouette only, never to the eyes or mouth.
