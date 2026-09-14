// Generates the Mini Dev-C++ app icon: a full-bleed navy/blue tile carrying a
// white "C" — the Dev-C++ chrome colours.
//   swift Tools/gen_icon.swift <out.png> [caret|underline]
import AppKit

let arguments = CommandLine.arguments
let outputPath = arguments.count > 1 ? arguments[1] : "Icon1024.png"
let variant = arguments.count > 2 ? arguments[2] : "caret"
let size: CGFloat = 1024

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// ── background: rounded tile with a vertical gradient ──────────────────────
let full = NSRect(x: 0, y: 0, width: size, height: size)
let radius = size * 0.185
NSBezierPath(roundedRect: full, xRadius: radius, yRadius: radius).addClip()

NSGradient(colors: [NSColor(calibratedRed: 0.17, green: 0.44, blue: 0.78, alpha: 1),
                    NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.30, alpha: 1)])?
    .draw(in: full, angle: -90)
NSGradient(colors: [NSColor.white.withAlphaComponent(0.16),
                    NSColor.white.withAlphaComponent(0.0)])?
    .draw(in: NSRect(x: 0, y: size * 0.5, width: size, height: size * 0.5), angle: -90)

// ── lockup: "C" + text caret, optically centred ────────────────────────────
let font = NSFont.systemFont(ofSize: 580, weight: .heavy)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white
]
let letter = "C" as NSString
let letterSize = letter.size(withAttributes: attributes)

// The caret is deliberately thinner than the letter stem and reaches above the
// cap line and below the baseline, so it reads as an insertion point rather
// than a second glyph (a "C" next to a cap-height bar reads as "CI").
let capHeight = font.capHeight
let descent = abs(font.descender)
let gap = capHeight * 0.20
let caretHeight = capHeight * 1.22
let caretWidth = capHeight * 0.25

let letterWidth = letterSize.width
let lockupWidth = variant == "caret" ? letterWidth + gap + caretWidth : letterWidth
// slight optical nudge right: the "C" carries its mass on the left
let letterX = (size - lockupWidth) / 2 + size * 0.008
let letterY = size / 2 - capHeight / 2 - descent
letter.draw(at: NSPoint(x: letterX, y: letterY), withAttributes: attributes)

if variant == "caret" {
    let caretRect = NSRect(x: letterX + letterWidth + gap,
                           y: size / 2 - caretHeight / 2,
                           width: caretWidth,
                           height: caretHeight)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: caretRect,
                 xRadius: caretWidth * 0.45, yRadius: caretWidth * 0.45).fill()
} else if variant == "underline" {
    let barHeight = size * 0.048
    let barWidth = size * 0.46
    let bar = NSRect(x: (size - barWidth) / 2,
                     y: letterY + abs(font.descender) - barHeight - size * 0.085,
                     width: barWidth,
                     height: barHeight)
    NSColor.white.withAlphaComponent(0.95).setFill()
    NSBezierPath(roundedRect: bar, xRadius: barHeight / 2, yRadius: barHeight / 2).fill()
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("icon: could not render PNG\n".utf8))
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath)")
