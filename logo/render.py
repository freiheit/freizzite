#!/usr/bin/env python3
"""Generate every derived logo artefact from logo/freizzite-logo.svg.

Run it with `just freizzite-logo`, which supplies cairosvg and pillow via uv.

Outputs:
  system_files/.../scalable/apps/freizzite-logo-icon.svg   head only, os-release LOGO=
  system_files/.../scalable/distributor-logo.svg           full robot, KDE launcher
  system_files/.../ublue-os/freizzite/logo.txt             fastfetch logo
  logo/freizzite-logo-512.png                              square, docs/ArtifactHub
  logo/freizzite-logo-1280x640.png                         wide banner, social preview

Geometry is read from the master by element id, so editing the master is
enough -- no constants are duplicated here.
"""

import re
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "logo" / "freizzite-logo.svg"
ICONS = ROOT / "system_files/usr/share/icons/hicolor/scalable"
COLS = 36  # width of the fastfetch logo, in terminal cells
SS = 8  # supersample per half-cell; kills antialiasing without dithering

RED, EAR, BLK = (162, 16, 16), (28, 15, 15), (0, 0, 0)
PALETTE = [RED, EAR, BLK]
FG = {c: f"\033[38;2;{c[0]};{c[1]};{c[2]}m" for c in PALETTE}
BG = {c: f"\033[48;2;{c[0]};{c[1]};{c[2]}m" for c in PALETTE}


def element(svg, eid):
    m = re.search(rf'<\w+[^>]*\bid="{eid}"[^>]*/?>', svg)
    if not m:
        raise SystemExit(f"master is missing id={eid!r}")
    return m.group(0)


def attr(el, name, cast=float):
    return cast(re.search(rf'\b{name}="([^"]+)"', el).group(1))


def drop(svg, *ids):
    for eid in ids:
        svg = svg.replace(element(svg, eid), "")
    return re.sub(r"\n\s*\n", "\n", svg)


def bbox(svg, res=2000):
    """Content extent in user units."""
    probe = re.sub(
        r"<svg[^>]*>",
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-80 -80 700 700" '
        f'width="{res}" height="{res}">',
        svg,
        count=1,
    )
    Path("/tmp/_probe.svg").write_text(probe)
    cairosvg.svg2png(url="/tmp/_probe.svg", write_to="/tmp/_probe.png")
    b = Image.open("/tmp/_probe.png").convert("RGBA").getbbox()
    k = 700 / res
    return [-80 + v * k for v in b]


def reframe(svg, axis, pad=0.05):
    """Square viewBox centred on the axis of symmetry, not on the bounding box:
    the mouth is deliberately asymmetric and would otherwise skew the frame."""
    x0, y0, x1, y1 = bbox(svg)
    half = max(axis - x0, x1 - axis)
    side = max(2 * half, y1 - y0) * (1 + 2 * pad)
    return re.sub(
        r"<svg[^>]*>",
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{axis - side / 2:.3f} '
        f'{(y0 + y1) / 2 - side / 2:.3f} {side:.3f} {side:.3f}">',
        svg,
        count=1,
    )


def bez(pts, t):
    m = 1 - t
    return tuple(
        m**3 * pts[0][i]
        + 3 * m * m * t * pts[1][i]
        + 3 * m * t * t * pts[2][i]
        + t**3 * pts[3][i]
        for i in (0, 1)
    )


def text_logo(svg):
    """Flat-colour half-block rendering, antennae as line characters."""
    vx, vy, vw, vh = [
        float(v) for v in re.search(r'viewBox="([^"]+)"', svg).group(1).split()
    ]
    rows = round(COLS * vh / vw / 2) * 2  # half-cells are square by construction
    u2c = lambda u: (u - vx) / vw * COLS
    u2r = lambda u: (u - vy) / vh * rows

    body = drop(svg, "antenna-left", "antenna-right", "bulb-left", "bulb-right")
    Path("/tmp/_body.svg").write_text(body)
    cairosvg.svg2png(
        url="/tmp/_body.svg",
        write_to="/tmp/_body.png",
        output_width=COLS * SS,
        output_height=rows * SS,
    )
    im = Image.open("/tmp/_body.png").convert("RGBA")

    def snap(px):
        r, g, b, a = px
        if a < 128:
            return None
        return min(
            PALETTE, key=lambda c: sum((c[i] - (r, g, b)[i]) ** 2 for i in range(3))
        )

    grid = []
    for y in range(rows):
        line = []
        for x in range(COLS):
            tally = {}
            for j in range(SS):
                for i in range(SS):
                    c = snap(im.getpixel((x * SS + i, y * SS + j)))
                    tally[c] = tally.get(c, 0) + 1
            line.append(max(tally, key=lambda k: (tally[k], k is not None)))
        grid.append(line)

    # eyes: paint the left one, mirror it -- identical squares whatever the phase
    eye = element(svg, "eye-left")
    ex, ey, ew = attr(eye, "x"), attr(eye, "y"), attr(eye, "width")
    side = max(1, round(u2c(vx + ew)))
    c0, r0 = round(u2c(ex)), round(u2r(ey))
    for r in range(r0, r0 + side):
        for c in range(c0, c0 + side):
            if 0 <= r < rows and 0 <= c < COLS:
                grid[r][c] = grid[r][COLS - 1 - c] = BLK

    # mouth: stem spans eye centre to eye centre, crossbar even on both sides
    eye_c = c0 + side // 2
    mouth = [
        (r, c) for r in range(r0 + side, rows) for c in range(COLS) if grid[r][c] == BLK
    ]
    if mouth:
        per_row = {r: sum(1 for rr, _ in mouth if rr == r) for r, _ in mouth}
        # half the widest row, not widest-minus-one: the stem's two half-rows can
        # differ by several cells depending on where the glyph falls on the grid
        stem = [r for r, w in per_row.items() if w >= max(per_row.values()) / 2]
        for r in range(min(stem), max(stem) + 1):
            for c in range(eye_c, COLS - eye_c):
                grid[r][c] = BLK
        off = [(r, c) for r, c in mouth if r not in stem]
        above = [(r, c) for r, c in off if r < min(stem)]
        if above:
            # above the stem sit the hook and the crossbar; the hook curls left,
            # so the crossbar is the rightmost of them. Counting cells instead is
            # phase-fragile -- the crossbar's tail can vanish into the stem rows.
            cb = max(c for _, c in above)
            rs = [r for r, c in off if c == cb] + stem
            # 2 half-cells each side: the glyph alone only yields 1 at this scale
            n = max(min(stem) - min(rs), max(rs) - max(stem), 2)
            for r in range(min(stem) - n, max(stem) + n + 1):
                if 0 <= r < rows:
                    grid[r][cb] = BLK

    # antennae: walk the left curve, one glyph per row, then mirror
    d = re.search(r'\bd="([^"]+)"', element(svg, "antenna-left")).group(1)
    n = [float(v) for v in re.findall(r"-?\d+\.?\d*", d)]
    pts = [(n[i], n[i + 1]) for i in range(0, 8, 2)]
    rc = {}
    for i in range(401):
        ux, uy = bez(pts, i / 400)
        rc.setdefault(int(u2r(uy) // 2), []).append(u2c(ux))
    rc = {r: sum(v) / len(v) for r, v in rc.items()}
    chars = {}
    order = sorted(rc)
    for j, r in enumerate(order):
        c = round(rc[r])
        if not (0 <= c < COLS and 0 <= r < rows // 2):
            continue
        if j == 0:
            g = "O"
        else:
            delta = rc[r] - rc[order[j - 1]]
            g = ("\\" if delta > 0.6 else "/") if abs(delta) > 0.6 else "|"
        chars[(r, c)] = g
        chars[(r, COLS - 1 - c)] = {"/": "\\", "\\": "/"}.get(g, g)

    out = []
    for r in range(rows // 2):
        line = ""
        for c in range(COLS):
            top, bot = grid[r * 2][c], grid[r * 2 + 1][c]
            if top is None and bot is None:
                line += "\033[0m" + chars.get((r, c), " ")
            elif top is None:
                line += "\033[0m" + FG[bot] + "▄"
            elif bot is None:
                line += "\033[0m" + FG[top] + "▀"
            else:
                line += BG[bot] + FG[top] + "▀"
        out.append(line.rstrip() + "\033[0m")
    plain = lambda s: re.sub(r"\033\[[0-9;]*m", "", s).strip()
    while out and not plain(out[0]):
        out.pop(0)
    while out and not plain(out[-1]):
        out.pop()
    return "\n".join(out) + "\n"


def png(svg, path, w, h):
    """Render at w x h, cropping the frame to that aspect around the content."""
    x0, y0, x1, y1 = bbox(svg)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    vh = (y1 - y0) * 1.02
    vw = max(vh * w / h, (x1 - x0) * 1.02)
    vh = vw * h / w
    framed = re.sub(
        r"<svg[^>]*>",
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{cx - vw / 2:.3f} '
        f'{cy - vh / 2:.3f} {vw:.3f} {vh:.3f}">',
        svg,
        count=1,
    )
    Path("/tmp/_png.svg").write_text(framed)
    cairosvg.svg2png(
        url="/tmp/_png.svg", write_to=str(path), output_width=w, output_height=h
    )
    print(f"  {path.relative_to(ROOT)} ({w}x{h})")


def main():
    master = MASTER.read_text()
    head_el = element(master, "head")
    axis = attr(head_el, "x") + attr(head_el, "width") / 2

    full = reframe(master, axis)
    head = reframe(drop(master, "neck", "body"), axis)

    targets = {
        ICONS / "apps/freizzite-logo-icon.svg": head,
        ICONS / "distributor-logo.svg": full,
        ROOT / "system_files/usr/share/ublue-os/freizzite/logo.txt": text_logo(head),
    }
    for path, content in targets.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        print(f"  {path.relative_to(ROOT)}")

    png(head, ROOT / "logo/freizzite-logo-512.png", 512, 512)
    png(
        drop(
            master,
            "neck",
            "body",
            "antenna-left",
            "antenna-right",
            "bulb-left",
            "bulb-right",
        ),
        ROOT / "logo/freizzite-logo-1280x640.png",
        1280,
        640,
    )


if __name__ == "__main__":
    main()
