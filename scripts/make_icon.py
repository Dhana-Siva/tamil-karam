#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024

# Create image
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw blue gradient background with rounded corners
def draw_rounded_rect_gradient(draw, size, radius, color_top, color_bottom):
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / size
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * t)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * t)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * t)
        bg_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    # Mask with rounded rect
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    bg.putalpha(mask)
    return bg

light_blue = (93, 173, 226)
dark_blue  = (26, 74, 138)
bg = draw_rounded_rect_gradient(draw, SIZE, 230, light_blue, dark_blue)
img = Image.alpha_composite(img, bg)
draw = ImageDraw.Draw(img)

# Tamil font
tamil_font_paths = [
    "/System/Library/Fonts/Supplemental/InaiMathi.ttf",
    "/Library/Fonts/NotoSansTamil-Bold.ttf",
    "/System/Library/Fonts/Tamil Sangam MN.ttc",
]
tamil_font = None
for path in tamil_font_paths:
    try:
        tamil_font = ImageFont.truetype(path, 260)
        print(f"Using Tamil font: {path}")
        break
    except:
        pass
if not tamil_font:
    tamil_font = ImageFont.load_default()

# Bottom label font (smaller)
tamil_label = None
for path in tamil_font_paths:
    try:
        tamil_label = ImageFont.truetype(path, 78)
        break
    except:
        pass
if not tamil_label:
    tamil_label = tamil_font

# Emoji font
emoji_font = None
try:
    emoji_font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", 160)
    print("Using Apple Color Emoji font")
except Exception as e:
    print(f"Emoji font error: {e}")

# Draw த (left)
draw.text((100, 260), "த", font=tamil_font, fill=(255, 255, 255, 242), anchor="lt")

# Draw ழ் (right)
draw.text((730, 260), "ழ்", font=tamil_font, fill=(255, 255, 255, 242), anchor="lt")

# Draw 🤝 emoji (centre)
if emoji_font:
    draw.text((512, 490), "🤝", font=emoji_font, fill=(255,255,255,255), anchor="mm")
else:
    draw.text((512, 490), "🤝", font=tamil_font, fill=(255,255,255,255), anchor="mm")

# Draw தமிழ் கரம் (bottom)
draw.text((512, 880), "தமிழ் கரம்", font=tamil_label, fill=(255, 255, 255, 210), anchor="mm")

# Save
out_path = "/Users/dhanasiva/Documents/Claude/tamil-karam/ios/app/Images.xcassets/AppIcon.appiconset/App-Icon-1024x1024@1x.png"
img.save(out_path, "PNG")
print(f"Saved to {out_path}")
