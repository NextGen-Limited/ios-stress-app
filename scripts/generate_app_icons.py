#!/usr/bin/env python3
"""Generate StressMonitor app icons for iOS app, Watch app, and Widget.

Design follows the character concept sheet:
- Ripple / Water Otter hero
- Blue stress ring
- Apple-style clean gradient, no alpha for App Store compliance
"""
from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
IOS_SET = ROOT / "StressMonitor/StressMonitor/Assets.xcassets/AppIcon.appiconset"
WATCH_SET = ROOT / "StressMonitor/StressMonitorWatch Watch App/Assets.xcassets/AppIcon.appiconset"
WIDGET_SET = ROOT / "StressMonitor/StressMonitorWidget/Assets.xcassets/AppIcon.appiconset"


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def gradient_bg(size: int, dark: bool = False) -> Image.Image:
    top = (5, 24, 44) if dark else (198, 238, 255)
    bottom = (37, 166, 229) if dark else (65, 195, 247)
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        # Slight diagonal light sweep
        for x in range(size):
            dx = (x / max(size - 1, 1) - 0.5) * 0.18
            tt = min(1, max(0, t + dx))
            px[x, y] = tuple(lerp(top[i], bottom[i], tt) for i in range(3))
    return img


def draw_soft_shadow(base: Image.Image, bbox: tuple[int, int, int, int], radius: int, offset: tuple[int, int], opacity: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    shifted = (bbox[0] + offset[0], bbox[1] + offset[1], bbox[2] + offset[0], bbox[3] + offset[1])
    d.ellipse(shifted, fill=(0, 32, 64, opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(radius))
    base.paste(Image.alpha_composite(base.convert("RGBA"), layer).convert("RGB"))


def draw_otter(draw: ImageDraw.ImageDraw, s: int, cx: float, cy: float, scale: float) -> None:
    """Draw a simple kawaii Ripple otter mascot with vector primitives."""
    # palette
    fur = (112, 86, 67)
    fur_dark = (78, 55, 42)
    muzzle = (239, 218, 190)
    blush = (255, 169, 170)
    white = (255, 255, 255)
    black = (30, 28, 32)
    blue = (79, 195, 247)
    blue_light = (179, 229, 252)

    def E(x0, y0, x1, y1, fill, outline=None, width=1):
        draw.ellipse((int(cx + x0 * scale), int(cy + y0 * scale), int(cx + x1 * scale), int(cy + y1 * scale)), fill=fill, outline=outline, width=max(1, int(width * scale)))

    def R(x0, y0, x1, y1, fill, radius=20, outline=None, width=1):
        draw.rounded_rectangle((int(cx + x0 * scale), int(cy + y0 * scale), int(cx + x1 * scale), int(cy + y1 * scale)), radius=int(radius * scale), fill=fill, outline=outline, width=max(1, int(width * scale)))

    # Tail / water wave behind
    draw.arc((int(cx - 98*scale), int(cy + 30*scale), int(cx + 98*scale), int(cy + 118*scale)), 190, 350, fill=blue_light, width=max(5, int(10*scale)))
    draw.arc((int(cx - 84*scale), int(cy + 42*scale), int(cx + 84*scale), int(cy + 116*scale)), 190, 350, fill=blue, width=max(3, int(6*scale)))

    # Ears
    E(-62, -76, -26, -38, fur_dark)
    E(26, -76, 62, -38, fur_dark)
    E(-52, -66, -34, -48, muzzle)
    E(34, -66, 52, -48, muzzle)

    # Head/body
    E(-74, -72, 74, 76, fur)
    E(-48, 4, 48, 88, muzzle)

    # Belly droplet
    E(-28, 32, 28, 78, blue_light)
    draw.polygon([
        (int(cx), int(cy + 22*scale)),
        (int(cx - 19*scale), int(cy + 49*scale)),
        (int(cx + 19*scale), int(cy + 49*scale)),
    ], fill=blue_light)

    # Eyes
    E(-42, -28, -14, 1, white)
    E(14, -28, 42, 1, white)
    E(-33, -20, -19, -5, black)
    E(19, -20, 33, -5, black)
    E(-28, -17, -24, -13, white)
    E(24, -17, 28, -13, white)

    # Nose + smile
    E(-9, 1, 9, 14, black)
    draw.arc((int(cx - 20*scale), int(cy + 7*scale), int(cx), int(cy + 28*scale)), 10, 90, fill=fur_dark, width=max(1, int(2*scale)))
    draw.arc((int(cx), int(cy + 7*scale), int(cx + 20*scale), int(cy + 28*scale)), 90, 170, fill=fur_dark, width=max(1, int(2*scale)))

    # Cheeks
    E(-54, 6, -35, 20, blush)
    E(35, 6, 54, 20, blush)

    # Paws
    E(-71, 24, -45, 51, fur_dark)
    E(45, 24, 71, 51, fur_dark)


def draw_icon(size: int, variant: str = "ios") -> Image.Image:
    dark = variant == "dark"
    img = gradient_bg(size, dark=dark).convert("RGBA")
    draw = ImageDraw.Draw(img)

    # ambient bubbles
    for i, (x, y, r, alpha) in enumerate([
        (0.18, 0.20, 0.045, 62), (0.78, 0.18, 0.035, 52), (0.85, 0.70, 0.050, 42),
        (0.14, 0.74, 0.030, 45), (0.70, 0.84, 0.026, 36)
    ]):
        bbox = (int((x-r)*size), int((y-r)*size), int((x+r)*size), int((y+r)*size))
        draw.ellipse(bbox, fill=(255, 255, 255, alpha), outline=(255, 255, 255, alpha + 25))

    # stress ring
    margin = int(size * 0.145)
    ring_box = (margin, margin, size - margin, size - margin)
    ring_w = max(8, int(size * 0.065))
    draw.ellipse(ring_box, outline=(255, 255, 255, 78), width=ring_w)
    # progress arc ~32% mild stress
    for offs, alpha in [(0, 255), (ring_w//3, 95)]:
        box = (ring_box[0]+offs, ring_box[1]+offs, ring_box[2]-offs, ring_box[3]-offs)
        draw.arc(box, start=-90, end=-90 + 116, fill=(0, 122, 255, alpha), width=max(3, ring_w - offs))

    # soft otter shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((int(size*.32), int(size*.68), int(size*.68), int(size*.78)), fill=(0, 55, 92, 80))
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(4, int(size*.025))))
    img = Image.alpha_composite(img, shadow)
    draw = ImageDraw.Draw(img)

    draw_otter(draw, size, size * 0.5, size * 0.51, size / 300)

    # small HealthKit-style pulse mark at top right
    pulse = [
        (0.655,0.298), (0.685,0.298), (0.705,0.260), (0.735,0.342),
        (0.760,0.298), (0.805,0.298)
    ]
    pts = [(int(x*size), int(y*size)) for x,y in pulse]
    draw.line(pts, fill=(255,255,255,215), width=max(3, int(size*.014)), joint="curve")

    return img.convert("RGB")


def save_resized(base: Image.Image, path: Path, px: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img = base.resize((px, px), Image.Resampling.LANCZOS)
    # Ensure no alpha channel (App Store rejects alpha in 1024 icon)
    if img.mode != "RGB":
        img = img.convert("RGB")
    img.save(path, "PNG", optimize=True)


def write_ios_contents(iconset: Path, prefix: str) -> None:
    images = []
    specs = [
        # iPhone notification/settings/spotlight/app
        ("iphone", "20x20", "2x", 40), ("iphone", "20x20", "3x", 60),
        ("iphone", "29x29", "2x", 58), ("iphone", "29x29", "3x", 87),
        ("iphone", "40x40", "2x", 80), ("iphone", "40x40", "3x", 120),
        ("iphone", "60x60", "2x", 120), ("iphone", "60x60", "3x", 180),
        # iPad
        ("ipad", "20x20", "1x", 20), ("ipad", "20x20", "2x", 40),
        ("ipad", "29x29", "1x", 29), ("ipad", "29x29", "2x", 58),
        ("ipad", "40x40", "1x", 40), ("ipad", "40x40", "2x", 80),
        ("ipad", "76x76", "1x", 76), ("ipad", "76x76", "2x", 152),
        ("ipad", "83.5x83.5", "2x", 167),
    ]
    for idiom, size, scale, px in specs:
        filename = f"{prefix}-{idiom}-{size.replace('.', '_')}@{scale}.png"
        images.append({"idiom": idiom, "size": size, "scale": scale, "filename": filename})
    images.append({"idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": f"{prefix}-ios-marketing-1024.png"})
    (iconset / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def write_watch_contents(iconset: Path, prefix: str) -> None:
    images = [
        {"idiom": "universal", "platform": "watchos", "size": "1024x1024", "filename": f"{prefix}-watchos-1024.png"}
    ]
    (iconset / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def generate_ios_set(iconset: Path, prefix: str, variant: str = "ios") -> None:
    base = draw_icon(1024, variant=variant)
    write_ios_contents(iconset, prefix)
    contents = json.loads((iconset / "Contents.json").read_text())
    for entry in contents["images"]:
        filename = entry["filename"]
        if entry["idiom"] == "ios-marketing":
            px = 1024
        else:
            # Convert point size * scale to pixels
            pt = float(entry["size"].split("x")[0])
            scale = int(entry["scale"].replace("x", ""))
            px = round(pt * scale)
        save_resized(base, iconset / filename, px)


def generate_watch_set(iconset: Path, prefix: str) -> None:
    base = draw_icon(1024, variant="dark")
    write_watch_contents(iconset, prefix)
    save_resized(base, iconset / f"{prefix}-watchos-1024.png", 1024)


def main() -> None:
    generate_ios_set(IOS_SET, "StressMonitor-AppIcon", variant="ios")
    generate_ios_set(WIDGET_SET, "StressMonitor-WidgetIcon", variant="ios")
    generate_watch_set(WATCH_SET, "StressMonitor-WatchIcon")
    print("Generated app icons:")
    for path in [IOS_SET, WATCH_SET, WIDGET_SET]:
        files = sorted(p.name for p in path.glob("*.png"))
        print(f"- {path.relative_to(ROOT)}: {len(files)} PNG files")


if __name__ == "__main__":
    main()
