#!/usr/bin/env python3
"""Generate DailySpeak app icon v2 — vibrant gradient + spectrum voice bars."""

from PIL import Image, ImageDraw, ImageFilter
import math

SCALE = 2
SIZE = 1024 * SCALE
FINAL = 1024
BG_RES = 512


def diagonal_gradient(size, colors):
    """Multi-stop diagonal gradient via H+V blend."""
    n = len(colors) - 1
    h_strip = Image.new('RGB', (size, 1))
    v_strip = Image.new('RGB', (1, size))
    for i in range(size):
        t = i / max(size - 1, 1)
        seg = min(int(t * n), n - 1)
        lt = (t * n) - seg
        c0, c1 = colors[seg], colors[seg + 1]
        c = tuple(int(c0[j] * (1 - lt) + c1[j] * lt) for j in range(3))
        h_strip.putpixel((i, 0), c)
        v_strip.putpixel((0, i), c)
    h_img = h_strip.resize((size, size), Image.BILINEAR)
    v_img = v_strip.resize((size, size), Image.BILINEAR)
    return Image.blend(h_img, v_img, 0.5)


def radial_glow(size, cx_pct, cy_pct, r_pct, color, opacity, power=1.5, steps=80):
    """Radial glow via concentric ellipses."""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = int(cx_pct * size), int(cy_pct * size)
    max_r = int(r_pct * size)
    for i in range(steps):
        t = i / steps
        r = int(max_r * (1 - t))
        if r <= 0:
            continue
        a = int((t ** power) * opacity * 255)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                     fill=(color[0], color[1], color[2], a))
    return layer


def bezier_points(p0, p1, p2, steps=28):
    """Quadratic Bezier curve points."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts


def tail_polygon(s):
    """Refined speech-bubble tail — compact and elegant."""
    left = bezier_points(
        (322 * s, 618 * s), (296 * s, 668 * s), (260 * s, 728 * s))
    right = bezier_points(
        (260 * s, 728 * s), (358 * s, 668 * s), (428 * s, 618 * s))
    return left + right


def main():
    s = SCALE

    # ── Rich gradient background: purple → blue → teal ──
    print("Background...")
    bg = diagonal_gradient(BG_RES, [
        (30, 15, 95),      # deep purple-indigo
        (25, 55, 195),     # vivid blue
        (6, 165, 195),     # bright teal-cyan
    ]).convert('RGBA')

    # Radial highlights for dimension
    g1 = radial_glow(BG_RES, 0.25, 0.18, 0.50, (90, 60, 220), 0.28, 1.4)
    g2 = radial_glow(BG_RES, 0.80, 0.78, 0.40, (6, 200, 210), 0.20, 1.6)
    g3 = radial_glow(BG_RES, 0.50, 0.50, 0.35, (60, 90, 230), 0.15, 2.0)
    bg = Image.alpha_composite(bg, g1)
    bg = Image.alpha_composite(bg, g2)
    bg = Image.alpha_composite(bg, g3)

    bg = bg.resize((SIZE, SIZE), Image.BILINEAR)

    # ── Shadow ──
    print("Shadow...")
    oy = int(18 * s)
    shadow_mask = Image.new('L', (SIZE, SIZE), 0)
    sd = ImageDraw.Draw(shadow_mask)
    sd.rounded_rectangle(
        [int(225 * s), int(198 * s) + oy, int(799 * s), int(622 * s) + oy],
        radius=int(82 * s), fill=170)
    tail_pts = tail_polygon(s)
    sd.polygon([(x, y + oy) for x, y in tail_pts], fill=140)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(radius=int(42 * s)))

    shadow_rgb = Image.new('RGB', (SIZE, SIZE), (8, 8, 40))
    shadow_layer = Image.merge('RGBA', (*shadow_rgb.split(), shadow_mask))
    bg = Image.alpha_composite(bg, shadow_layer)

    # ── Speech bubble ──
    print("Bubble...")
    bubble = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bubble)
    bd.rounded_rectangle(
        [int(225 * s), int(198 * s), int(799 * s), int(622 * s)],
        radius=int(82 * s), fill=(255, 255, 255, 252))
    bd.polygon(tail_pts, fill=(255, 255, 255, 252))
    bg = Image.alpha_composite(bg, bubble)

    # ── Voice waveform bars — spectrum colors ──
    print("Waveform...")
    bars_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    bdr = ImageDraw.Draw(bars_layer)
    cx, cy = int(512 * s), int(412 * s)
    bw = int(40 * s)
    br = int(20 * s)

    # Spectrum colors: teal → blue → purple → blue → teal (symmetric)
    spec = [
        (-178, 42, (10, 145, 130)),     # teal
        (-95,  78, (30, 90, 220)),      # blue
        (-18, 104, (88, 28, 175)),      # purple
        (60,   68, (30, 90, 220)),      # blue
        (138,  36, (10, 145, 130)),     # teal
    ]
    for xo, hh, col in spec:
        x1 = cx + int(xo * s)
        y1 = cy - int(hh * s)
        x2 = x1 + bw
        y2 = cy + int(hh * s)
        bdr.rounded_rectangle([x1, y1, x2, y2], radius=br,
                              fill=(col[0], col[1], col[2], 230))
    bg = Image.alpha_composite(bg, bars_layer)

    # ── Finalize ──
    print("Downscaling...")
    final = bg.resize((FINAL, FINAL), Image.LANCZOS)
    out = Image.new('RGB', (FINAL, FINAL))
    out.paste(final, mask=final.split()[3])

    path = 'DailySpeak/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    out.save(path, 'PNG', optimize=True)
    out.save('AppIcon_preview.png', 'PNG', optimize=True)
    print(f"Done → {path}")


if __name__ == '__main__':
    main()
