#!/usr/bin/env python3
"""Generate TamilKaram app icon using macOS NSImage for proper Tamil rendering."""
import Cocoa

SIZE = 1024
OUT_PATH = "/Users/dhanasiva/Documents/Claude/tamil-karam/ios/app/Images.xcassets/AppIcon.appiconset/App-Icon-1024x1024@1x.png"

ns_img = Cocoa.NSImage.alloc().initWithSize_((SIZE, SIZE))
ns_img.lockFocus()
ctx = Cocoa.NSGraphicsContext.currentContext().CGContext()

import Quartz

# --- Rounded rect clip ---
path = Quartz.CGPathCreateWithRoundedRect(
    Quartz.CGRectMake(0, 0, SIZE, SIZE), 230, 230, None
)
Quartz.CGContextAddPath(ctx, path)
Quartz.CGContextClip(ctx)

# --- Blue gradient ---
cs = Quartz.CGColorSpaceCreateDeviceRGB()
gradient = Quartz.CGGradientCreateWithColorComponents(
    cs,
    [93/255, 173/255, 226/255, 1.0,   # light blue (top)
     26/255,  74/255, 138/255, 1.0],  # dark blue (bottom)
    [0.0, 1.0], 2
)
Quartz.CGContextDrawLinearGradient(
    ctx, gradient,
    Quartz.CGPointMake(512, SIZE),   # top
    Quartz.CGPointMake(512, 0),      # bottom
    0
)

# Helper: draw text centered at (cx, cy)
def draw_text(text, font_name, size, cx, cy, alpha=0.95):
    font = Cocoa.NSFont.fontWithName_size_(font_name, size)
    if not font:
        font = Cocoa.NSFont.systemFontOfSize_(size)
    attrs = {
        Cocoa.NSFontAttributeName: font,
        Cocoa.NSForegroundColorAttributeName: Cocoa.NSColor.colorWithCalibratedRed_green_blue_alpha_(1, 1, 1, alpha),
    }
    ns_str = Cocoa.NSAttributedString.alloc().initWithString_attributes_(text, attrs)
    w, h = ns_str.size()
    ns_str.drawAtPoint_((cx - w / 2, cy - h / 2))

# த (left)
draw_text("த", "Tamil Sangam MN", 300, 175, 490)

# 🤝 emoji (centre)
draw_text("🤝", "Apple Color Emoji", 200, 512, 480)

# ழ் (right)
draw_text("ழ்", "Tamil Sangam MN", 300, 848, 490)

# தமிழ் கரம் (bottom)
draw_text("தமிழ் கரம்", "Tamil Sangam MN", 78, 512, 100, alpha=0.85)

ns_img.unlockFocus()

# Save PNG
tiff = ns_img.TIFFRepresentation()
bitmap = Cocoa.NSBitmapImageRep.imageRepWithData_(tiff)
png_data = bitmap.representationUsingType_properties_(Cocoa.NSBitmapImageFileTypePNG, {})
png_data.writeToFile_atomically_(OUT_PATH, True)
print(f"Saved: {OUT_PATH}")
