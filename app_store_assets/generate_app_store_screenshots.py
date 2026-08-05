#!/usr/bin/env python3
"""Generate App Store screenshot sets from the seven approved ApexLoad captures."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE_DIR = ROOT / "source_screenshots"
OUTPUT_DIR = ROOT / "screenshots"
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")

SCREENSHOTS = [
    (
        "01_download_media",
        "IMG_0062.PNG",
        "Download media in a few taps",
        "Paste a supported link, choose a quality, and save.",
    ),
    (
        "02_quick_editor",
        "IMG_0063.PNG",
        "Edit videos in seconds",
        "Trim, mute, swap audio, or extract sound.",
    ),
    (
        "03_choose_quality",
        "IMG_0064.PNG",
        "Choose your preferred quality",
        "Pick the available format and resolution before saving.",
    ),
    (
        "04_preview_and_save",
        "IMG_0066.PNG",
        "Preview before you save",
        "Review your media and choose video or audio.",
    ),
    (
        "05_organized_downloads",
        "IMG_0068.PNG",
        "Keep every download organized",
        "Search and filter videos, audio, images, and edits.",
    ),
    (
        "06_premium",
        "IMG_0069.PNG",
        "Unlock ApexLoad Premium",
        "Get unlimited downloads, premium tools, and no ads.",
    ),
    (
        "07_home",
        "IMG_0070.PNG",
        "All your tools in one place",
        "Download, edit, organize, and save from one powerful app.",
    ),
]

IPHONE_65 = (1242, 2688)
IPHONE_69 = (1290, 2796)
IPAD_13 = (2064, 2752)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_PATH), size=size)


def fit_cover(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    """Scale and center-crop with no distortion."""
    tw, th = target
    scale = max(tw / image.width, th / image.height)
    resized = image.resize(
        (math.ceil(image.width * scale), math.ceil(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - tw) // 2
    top = (resized.height - th) // 2
    return resized.crop((left, top, left + tw, top + th)).convert("RGB")


def vertical_gradient(size: tuple[int, int]) -> Image.Image:
    width, height = size
    top = (8, 15, 42)
    bottom = (18, 22, 58)
    strip = Image.new("RGB", (1, height))
    pixels = strip.load()
    for y in range(height):
        t = y / max(1, height - 1)
        pixels[0, y] = tuple(
            round(top[channel] * (1 - t) + bottom[channel] * t)
            for channel in range(3)
        )
    return strip.resize((width, height))


def rounded_screenshot(image: Image.Image, size: tuple[int, int], radius: int) -> Image.Image:
    fitted = fit_cover(image, size).convert("RGBA")
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    fitted.putalpha(mask)
    return fitted


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    text_font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    canvas_width: int,
) -> None:
    box = draw.textbbox((0, 0), text, font=text_font)
    x = (canvas_width - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=text_font, fill=fill)


def make_ipad_presentation(
    source: Image.Image,
    title: str,
    subtitle: str,
) -> Image.Image:
    width, height = IPAD_13
    canvas = vertical_gradient(IPAD_13).convert("RGBA")

    # Soft brand glow behind the device.
    glow = Image.new("RGBA", IPAD_13, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((330, 430, 1734, 2560), fill=(38, 211, 255, 56))
    glow = glow.filter(ImageFilter.GaussianBlur(150))
    canvas = Image.alpha_composite(canvas, glow)

    draw = ImageDraw.Draw(canvas)
    draw_centered_text(draw, title, 120, font(92), (255, 255, 255), width)
    draw_centered_text(draw, subtitle, 245, font(42), (185, 194, 219), width)

    phone_size = (900, 1948)
    phone_x = (width - phone_size[0]) // 2
    phone_y = 505
    corner_radius = 76

    # Layered shadow and thin cyan/violet frame.
    shadow = Image.new("RGBA", IPAD_13, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (
            phone_x - 26,
            phone_y + 18,
            phone_x + phone_size[0] + 26,
            phone_y + phone_size[1] + 54,
        ),
        radius=corner_radius + 22,
        fill=(0, 0, 0, 145),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(38))
    canvas = Image.alpha_composite(canvas, shadow)

    frame = Image.new("RGBA", IPAD_13, (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle(
        (
            phone_x - 10,
            phone_y - 10,
            phone_x + phone_size[0] + 10,
            phone_y + phone_size[1] + 10,
        ),
        radius=corner_radius + 10,
        fill=(25, 205, 255, 255),
    )
    frame_draw.rounded_rectangle(
        (
            phone_x - 5,
            phone_y - 5,
            phone_x + phone_size[0] + 5,
            phone_y + phone_size[1] + 5,
        ),
        radius=corner_radius + 5,
        fill=(110, 86, 255, 255),
    )
    canvas = Image.alpha_composite(canvas, frame)

    phone = rounded_screenshot(source, phone_size, corner_radius)
    canvas.alpha_composite(phone, (phone_x, phone_y))

    # Small, restrained brand footer.
    draw = ImageDraw.Draw(canvas)
    draw_centered_text(draw, "ApexLoad", 2600, font(42), (128, 142, 184), width)
    return canvas.convert("RGB")


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(path, format="PNG", optimize=True)


def main() -> None:
    for folder in ("iphone_6_5", "iphone_6_9", "ipad_13"):
        (OUTPUT_DIR / folder).mkdir(parents=True, exist_ok=True)

    for stem, source_name, title, subtitle in SCREENSHOTS:
        source_path = SOURCE_DIR / source_name
        source = Image.open(source_path).convert("RGB")
        save_png(fit_cover(source, IPHONE_65), OUTPUT_DIR / "iphone_6_5" / f"{stem}.png")
        save_png(fit_cover(source, IPHONE_69), OUTPUT_DIR / "iphone_6_9" / f"{stem}.png")
        save_png(
            make_ipad_presentation(source, title, subtitle),
            OUTPUT_DIR / "ipad_13" / f"{stem}.png",
        )

    print(f"Generated {len(SCREENSHOTS) * 3} screenshots in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
