#!/usr/bin/env python3
"""Generate App Store marketing screenshots for ApexLoad.

Builds a presentation frame around each device capture: brand gradient,
headline, subheadline and a device mockup. The capture is scaled to fit and
never cropped, so no UI is cut off mid-word.

Set BLUR_REGIONS on a screenshot to obscure third-party or personal content
before it is composited (fractional x0, y0, x1, y1 of the capture).

Usage:
    python3 generate_marketing_screenshots.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
SOURCE_DIR = ROOT / "source_v2"
OUTPUT_DIR = ROOT / "marketing_screenshots"
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")

# ApexLoad brand palette (lib/core/constants/app_constants.dart).
BG_TOP = (11, 16, 32)
BG_BOTTOM = (17, 23, 53)
ACCENT_START = (108, 99, 255)
ACCENT_END = (0, 212, 255)
TEXT_PRIMARY = (255, 255, 255)
TEXT_SECONDARY = (170, 179, 197)


class Shot:
    def __init__(self, slug, source, headline, subheadline, blur_regions=()):
        self.slug = slug
        self.source = source
        self.headline = headline
        self.subheadline = subheadline
        self.blur_regions = blur_regions


# Captures are taken against the 5.2.3-compliant build: no YouTube anywhere,
# no watermark option, "Video Saver & Editor" subtitle, ownership notice shown.
SCREENSHOTS = [
    Shot(
        "01_home",
        "01_home.png",
        "Save and edit\nin one place",
        "TikTok, Instagram, Facebook, X, Pinterest and more.",
    ),
    Shot(
        "02_quality",
        "02_quality.png",
        "Pick the quality\nyou want",
        "From 480p to 4K, or keep just the audio as MP3.",
    ),
    Shot(
        "03_edit",
        "03_edit_tools.png",
        "A real editor,\nbuilt in",
        "Trim, mute and extract audio — all on device.",
    ),
    Shot(
        "04_reels",
        "04_reels.png",
        "Ready for Reels\nand Shorts",
        "One tap to a vertical 1080x1920 export.",
    ),
    Shot(
        "05_gif",
        "05_gif.png",
        "Turn any video\ninto a GIF",
        "Choose the frame rate, speed, size and loop.",
    ),
    Shot(
        "06_library",
        "06_library.png",
        "Everything\nstays organized",
        "Search and filter every download you save.",
        # Third-party video thumbnail in the first list row.
        blur_regions=((0.05, 0.355, 0.22, 0.45),),
    ),
    Shot(
        "07_whatsapp",
        "07_whatsapp.png",
        "Save WhatsApp\nstatus updates",
        "View a status, then save the photo or video.",
        # Contact name, avatar and reply strip belong to a real person.
        blur_regions=(
            (0.55, 0.180, 0.81, 0.228),
            (0.06, 0.825, 0.90, 0.860),
        ),
    ),
    Shot(
        "08_editor",
        "08_editor_home.png",
        "All your tools\nin one place",
        "Download, edit, convert and save — no account.",
        blur_regions=((0.08, 0.405, 0.24, 0.48),),
    ),
]

# App Store Connect accepted sizes.
DEVICES = {
    "iphone_6_9": (1290, 2796),
    "iphone_6_5": (1242, 2688),
    "ipad_13": (2064, 2752),
}


def font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont:
    loaded = ImageFont.truetype(str(FONT_PATH), size=size)
    try:
        loaded.set_variation_by_name("Bold" if bold else "Regular")
    except Exception:
        pass
    return loaded


def diagonal_gradient(size: tuple[int, int]) -> Image.Image:
    width, height = size
    small = Image.new("RGB", (2, 2))
    small.putpixel((0, 0), BG_TOP)
    small.putpixel((1, 0), BG_BOTTOM)
    small.putpixel((0, 1), BG_BOTTOM)
    small.putpixel((1, 1), BG_TOP)
    return small.resize((width, height), Image.Resampling.BICUBIC)


def accent_glow(canvas: Image.Image, center: tuple[int, int], radius: int) -> Image.Image:
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    cx, cy = center
    draw.ellipse(
        (cx - radius, cy - radius // 2, cx + radius, cy + radius // 2),
        fill=(*ACCENT_END, 46),
    )
    draw.ellipse(
        (cx - radius // 2, cy - radius // 3, cx + radius // 2, cy + radius // 3),
        fill=(*ACCENT_START, 40),
    )
    return Image.alpha_composite(canvas, glow.filter(ImageFilter.GaussianBlur(radius // 3)))


def apply_blur_regions(image: Image.Image, regions) -> Image.Image:
    """Obscure third-party media and personal details before compositing."""
    if not regions:
        return image
    result = image.copy()
    for x0, y0, x1, y1 in regions:
        box = (
            round(x0 * result.width),
            round(y0 * result.height),
            round(x1 * result.width),
            round(y1 * result.height),
        )
        patch = result.crop(box)
        radius = max(8, round(min(patch.width, patch.height) * 0.35))
        result.paste(patch.filter(ImageFilter.GaussianBlur(radius)), box)
    return result


def fit_contain(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    bw, bh = box
    scale = min(bw / image.width, bh / image.height)
    return image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )


def device_mockup(capture: Image.Image, box: tuple[int, int]) -> Image.Image:
    screen = fit_contain(capture, box).convert("RGBA")
    radius = round(screen.width * 0.085)

    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screen.width, screen.height), radius=radius, fill=255
    )
    screen.putalpha(mask)

    bezel = max(6, round(screen.width * 0.012))
    pad = bezel * 6
    plate = Image.new(
        "RGBA",
        (screen.width + bezel * 2 + pad * 2, screen.height + bezel * 2 + pad * 2),
        (0, 0, 0, 0),
    )

    shadow = Image.new("RGBA", plate.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (pad, pad + bezel * 2, plate.width - pad, plate.height - pad + bezel),
        radius=radius + bezel,
        fill=(0, 0, 0, 165),
    )
    plate = Image.alpha_composite(plate, shadow.filter(ImageFilter.GaussianBlur(pad // 2)))

    frame_box = (pad, pad, plate.width - pad, plate.height - pad)
    gradient = Image.new("RGBA", plate.size, (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(gradient)
    height = frame_box[3] - frame_box[1]
    for y in range(height):
        t = y / max(1, height - 1)
        gdraw.line(
            [(frame_box[0], frame_box[1] + y), (frame_box[2], frame_box[1] + y)],
            fill=tuple(
                round(ACCENT_START[c] * (1 - t) + ACCENT_END[c] * t) for c in range(3)
            )
            + (255,),
        )
    frame_mask = Image.new("L", plate.size, 0)
    ImageDraw.Draw(frame_mask).rounded_rectangle(
        frame_box, radius=radius + bezel, fill=255
    )
    gradient.putalpha(frame_mask)
    plate = Image.alpha_composite(plate, gradient)

    plate.alpha_composite(screen, (pad + bezel, pad + bezel))
    return plate


def draw_block(draw, lines, top, text_font, fill, width, leading=1.16) -> int:
    y = top
    for line in lines:
        box = draw.textbbox((0, 0), line, font=text_font)
        line_height = box[3] - box[1]
        draw.text(
            ((width - (box[2] - box[0])) // 2 - box[0], y - box[1]),
            line,
            font=text_font,
            fill=fill,
        )
        y += round(line_height * leading) + round(text_font.size * 0.28)
    return y


def compose(capture: Image.Image, size: tuple[int, int], shot: Shot) -> Image.Image:
    width, height = size
    is_tablet = width >= 2000
    canvas = diagonal_gradient(size).convert("RGBA")
    canvas = accent_glow(canvas, (width // 2, round(height * 0.60)), round(width * 0.85))

    # Layout metrics authored against iPhone 6.9". The tablet uses a smaller
    # type scale so the wider canvas does not turn the headline into a banner.
    scale = width / 1290 * (0.62 if is_tablet else 1.0)
    draw = ImageDraw.Draw(canvas)

    y = round(150 * scale) if not is_tablet else round(190 * scale)
    y = draw_block(draw, shot.headline.split("\n"), y, font(round(96 * scale), bold=True),
                   TEXT_PRIMARY, width)
    y += round(14 * scale)
    y = draw_block(draw, [shot.subheadline], y, font(round(42 * scale)),
                   TEXT_SECONDARY, width)

    top_of_device = y + round(48 * scale)
    available = (
        round(width * (0.44 if is_tablet else 0.72)),
        height - top_of_device - round(70 * scale),
    )
    mockup = device_mockup(capture, available)
    canvas.alpha_composite(mockup, ((width - mockup.width) // 2, top_of_device))
    return canvas.convert("RGB")


def main() -> None:
    missing = [s.source for s in SCREENSHOTS if not (SOURCE_DIR / s.source).exists()]
    if missing:
        raise SystemExit(f"Missing source captures: {', '.join(missing)}")

    for folder, size in DEVICES.items():
        target = OUTPUT_DIR / folder
        target.mkdir(parents=True, exist_ok=True)
        for shot in SCREENSHOTS:
            capture = Image.open(SOURCE_DIR / shot.source).convert("RGB")
            capture = apply_blur_regions(capture, shot.blur_regions)
            image = compose(capture, size, shot)
            out = target / f"{shot.slug}.png"
            image.save(out, format="PNG", optimize=True)
            print(f"wrote {out.relative_to(ROOT)}  {image.width}x{image.height}")


if __name__ == "__main__":
    main()
