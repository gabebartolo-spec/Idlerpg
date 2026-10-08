"""Render an original Mossgate specimen. Requires Pillow; pass --output FILE."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, default=root / "art/review/mossgate-specimen.png")
args = parser.parse_args()
image = Image.new("RGB", (1100, 1040), "#272820")
draw = ImageDraw.Draw(image)
lines = [
    ("Mossgate", 84, "Semibold"),
    ("Original letters for small adventures", 34, "Regular"),
    ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", 35, "Semibold"),
    ("abcdefghijklmnopqrstuvwxyz", 42, "Regular"),
    ("0123456789   I l 1   O 0   rn m", 42, "Regular"),
    ("Gentle Greenway  ·  5 min  ·  +43 gold", 36, "Semibold"),
    ("Adventure complete!", 34, "Semibold"),
    ("Stew ready: 2   Thornward: ready", 28, "Regular"),
    ("The quick brown fox jumps over the lazy dog.", 26, "Regular"),
    ("HP 47/47   Gold 183   Next catch: 7s", 24, "Semibold"),
    ("Élodie  ·  Zoë  ·  Åsta  ·  François", 30, "Regular"),
    ("Small screen sizes", 26, "Semibold"),
    ("47/47 HP · 183 gold   →   Exploring · stage 3/5", 14, "Semibold"),
    ("Stew: 2 perch + 1 carp + 1 herb", 13, "Regular"),
]
y = 40
for text, size, style in lines:
    font = ImageFont.truetype(str(root / "assets/fonts" / ("Mossgate-" + style + ".ttf")), size)
    draw.text((45, y), text, font=font, fill="#eddfbe" if style == "Regular" else "#e5ba49")
    y += size + 23
args.output.parent.mkdir(parents=True, exist_ok=True)
image.save(args.output)
print(args.output)
