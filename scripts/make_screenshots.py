#!/usr/bin/env python3
"""
Generates App Store screenshots for Tamil Karam.
Produces:
  - iphone_6_5.png   (1284 x 2778 — iPhone 14 Plus / 6.5-inch)
  - ipad_13.png      (2048 x 2732 — iPad Pro 13-inch)
"""

from PIL import Image, ImageDraw, ImageFont
import os, sys

OUT_DIR = os.path.join(os.path.dirname(__file__), "../screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

# ── Colours ────────────────────────────────────────────────────────────────────
BG_TOP    = (93,  173, 226)   # light blue
BG_BOT    = (26,  74,  138)   # dark blue
WHITE     = (255, 255, 255)
CARD_BG   = (255, 255, 255)
RED_TEXT  = (220,  50,  50)
GREEN_TEXT= ( 40, 167,  69)
ORANGE    = (255, 149,   0)
DARK_TEXT = ( 30,  30,  30)
GREY_TEXT = (120, 120, 120)
BTN_RED   = (230,  57,  63)
BTN_GREEN = ( 40, 167,  69)

def gradient_bg(draw, w, h):
    for y in range(h):
        t = y / h
        r = int(BG_TOP[0] + t * (BG_BOT[0] - BG_TOP[0]))
        g = int(BG_TOP[1] + t * (BG_BOT[1] - BG_TOP[1]))
        b = int(BG_TOP[2] + t * (BG_BOT[2] - BG_TOP[2]))
        draw.line([(0, y), (w, y)], fill=(r, g, b))

def rounded_rect(draw, xy, radius, fill, outline=None, outline_width=2):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill,
                            outline=outline, width=outline_width)

def center_text(draw, text, font, y, w, fill=WHITE):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, y), text, font=font, fill=fill)

def make_screenshot(W, H, out_path, scale=1.0):
    img  = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, W, H)

    S = scale   # scale factor relative to iPhone base

    def sp(n): return int(n * S)   # scaled pixels

    # ── App name at top ───────────────────────────────────────────────────────
    try:
        font_title  = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", sp(72))
        font_sub    = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", sp(38))
        font_label  = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", sp(32))
        font_body   = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", sp(36))
        font_btn    = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", sp(40))
        font_tamil  = ImageFont.truetype("/System/Library/Fonts/Tamil Sangam MN.ttc", sp(44))
        font_tamil_lg = ImageFont.truetype("/System/Library/Fonts/Tamil Sangam MN.ttc", sp(56))
    except:
        font_title  = ImageFont.load_default()
        font_sub    = font_title
        font_label  = font_title
        font_body   = font_title
        font_btn    = font_title
        font_tamil  = font_title
        font_tamil_lg = font_title

    pad = sp(60)

    # Title block
    title_y = sp(140)
    center_text(draw, "தமிழ் 🤝 கரம்", font_tamil_lg, title_y, W)
    center_text(draw, "Tamil Karam", font_title, title_y + sp(90), W)
    center_text(draw, "AI Tamil Grammar Keyboard", font_sub, title_y + sp(180), W,
                fill=(200, 230, 255))

    # ── Keyboard card ─────────────────────────────────────────────────────────
    card_y = sp(440)
    card_h = sp(520)
    card_x = pad
    card_x2 = W - pad
    rounded_rect(draw, [card_x, card_y, card_x2, card_y + card_h],
                 radius=sp(30), fill=(255, 255, 255))

    # "Fix Tamil Grammar" button inside card
    btn_mx = sp(40)
    btn_y  = card_y + sp(40)
    btn_h  = sp(90)
    rounded_rect(draw, [card_x + btn_mx, btn_y,
                        card_x2 - btn_mx, btn_y + btn_h],
                 radius=sp(18), fill=BTN_RED)
    center_text(draw, "✓  Fix Tamil Grammar", font_btn, btn_y + sp(22), W,
                fill=WHITE)

    # Status label
    center_text(draw, "✅ Fixed!", font_label, btn_y + btn_h + sp(20), W,
                fill=GREY_TEXT)

    # Before / After card
    diff_y = btn_y + btn_h + sp(80)
    diff_h = sp(280)
    rounded_rect(draw, [card_x + btn_mx, diff_y,
                        card_x2 - btn_mx, diff_y + diff_h],
                 radius=sp(18), fill=(248, 248, 248))

    inner_x = card_x + btn_mx + sp(24)
    draw.text((inner_x, diff_y + sp(20)), "Before", font=font_label,
              fill=GREY_TEXT)
    before_txt = "நான் போறேன்"
    draw.text((inner_x, diff_y + sp(60)), before_txt, font=font_tamil,
              fill=RED_TEXT)
    # strikethrough
    bb = draw.textbbox((inner_x, diff_y + sp(60)), before_txt, font=font_tamil)
    mid_y = (bb[1] + bb[3]) // 2
    draw.line([(bb[0], mid_y), (bb[2], mid_y)], fill=RED_TEXT, width=sp(3))

    # divider
    div_y = diff_y + sp(130)
    draw.line([(card_x + btn_mx + sp(16), div_y),
               (card_x2 - btn_mx - sp(16), div_y)],
              fill=(220, 220, 220), width=sp(2))

    draw.text((inner_x, div_y + sp(18)), "After", font=font_label,
              fill=GREY_TEXT)
    draw.text((inner_x, div_y + sp(58)), "நான் போகிறேன்", font=font_tamil,
              fill=GREEN_TEXT)

    # Keep / Undo buttons
    half = (card_x2 - btn_mx - card_x - btn_mx) // 2
    keep_x  = card_x + btn_mx
    undo_x  = keep_x + half + sp(12)
    btn2_y  = diff_y + diff_h + sp(20)
    btn2_h  = sp(70)
    rounded_rect(draw, [keep_x, btn2_y, keep_x + half - sp(12), btn2_y + btn2_h],
                 radius=sp(14), fill=BTN_GREEN)
    center_text(draw, "✓ Keep", font_label, btn2_y + sp(18),
                keep_x + (half - sp(12)) // 2 * 2, fill=WHITE)

    rounded_rect(draw, [undo_x, btn2_y, card_x2 - btn_mx, btn2_y + btn2_h],
                 radius=sp(14), fill=(255, 230, 230))
    # undo label
    undo_mid = undo_x + (card_x2 - btn_mx - undo_x) // 2
    bb2 = draw.textbbox((0, 0), "✕ Undo", font=font_label)
    draw.text((undo_mid - (bb2[2] - bb2[0]) // 2, btn2_y + sp(18)),
              "✕ Undo", font=font_label, fill=BTN_RED)

    # ── Feature bullets ───────────────────────────────────────────────────────
    feats_y = card_y + card_h + sp(50)
    features = [
        ("✓", "Works in WhatsApp, Messages & all apps"),
        ("✓", "AI-powered Tamil grammar correction"),
        ("✓", "Before & after comparison"),
        ("✓", "50 free corrections per month"),
    ]
    for icon, text in features:
        center_text(draw, f"{icon}  {text}", font_sub, feats_y, W,
                    fill=(200, 230, 255))
        feats_y += sp(68)

    img.save(out_path, "PNG")
    print(f"✅ Saved: {out_path}")

# ── Generate both sizes ────────────────────────────────────────────────────────
# iPhone 6.5-inch (1284 × 2778)
make_screenshot(1284, 2778, f"{OUT_DIR}/iphone_6_5.png", scale=1.0)

# iPad 13-inch (2048 × 2732)
make_screenshot(2048, 2732, f"{OUT_DIR}/ipad_13.png", scale=1.6)

print("\nScreenshots saved to:", OUT_DIR)
