import AppKit
import CoreGraphics

let SIZE: CGFloat = 1024
let OUT = "/Users/dhanasiva/Documents/Claude/tamil-karam/ios/app/Images.xcassets/AppIcon.appiconset/App-Icon-1024x1024@1x.png"

let img = NSImage(size: NSSize(width: SIZE, height: SIZE))
img.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// Rounded rect clip
let rrPath = CGPath(roundedRect: CGRect(x:0,y:0,width:SIZE,height:SIZE), cornerWidth:230, cornerHeight:230, transform:nil)
ctx.addPath(rrPath); ctx.clip()

// Blue gradient (top=light, bottom=dark — Quartz y=0 is bottom)
let cs = CGColorSpaceCreateDeviceRGB()
let grad = CGGradient(colorSpace: cs,
    colorComponents: [26/255,74/255,138/255,1,  93/255,173/255,226/255,1],
    locations: [0,1], count: 2)!
ctx.drawLinearGradient(grad,
    start: CGPoint(x: SIZE/2, y: 0),
    end:   CGPoint(x: SIZE/2, y: SIZE),
    options: [])

// Helper: draw centered NSAttributedString
func drawText(_ text: String, fontName: String, size: CGFloat, cx: CGFloat, cy: CGFloat, alpha: CGFloat = 0.95) {
    let font = NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white.withAlphaComponent(alpha)
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let sz = str.size()
    str.draw(at: NSPoint(x: cx - sz.width/2, y: cy - sz.height/2))
}

// த (left)
drawText("த", fontName: "Tamil Sangam MN", size: 310, cx: 175, cy: 460)

// 🤝 (centre)
drawText("🤝", fontName: "Apple Color Emoji", size: 210, cx: 512, cy: 455)

// ழ் (right)
drawText("ழ்", fontName: "Tamil Sangam MN", size: 310, cx: 848, cy: 460)

// தமிழ் கரம் (bottom)
drawText("தமிழ் கரம்", fontName: "Tamil Sangam MN", size: 80, cx: 512, cy: 95, alpha: 0.85)

img.unlockFocus()

// Save PNG
if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try! png.write(to: URL(fileURLWithPath: OUT))
    print("Saved: \(OUT)")
} else {
    print("Failed to save")
}
