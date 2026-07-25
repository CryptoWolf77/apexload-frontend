import AppKit
import CoreGraphics
import CoreText
import Foundation

private let canvasSize = 1024
private let materialBoltRounded: UniChar = 0xF5CA
private let materialIconsURL = URL(
  fileURLWithPath:
    "/Users/administrator/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"
)

private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
  CGColor(
    colorSpace: CGColorSpaceCreateDeviceRGB(),
    components: [red / 255, green / 255, blue / 255, 1]
  )!
}

guard CommandLine.arguments.count == 2 else {
  fputs("Usage: swift generate_apexload_app_icon.swift <output.png>\n", stderr)
  exit(64)
}

guard
  let provider = CGDataProvider(url: materialIconsURL as CFURL),
  let graphicsFont = CGFont(provider),
  let context = CGContext(
    data: nil,
    width: canvasSize,
    height: canvasSize,
    bitsPerComponent: 8,
    bytesPerRow: canvasSize * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
  )
else {
  fputs("Could not load Flutter's Material Icons font or create the image canvas.\n", stderr)
  exit(1)
}

let gradient = CGGradient(
  colorsSpace: CGColorSpaceCreateDeviceRGB(),
  colors: [
    color(108, 99, 255),
    color(0, 212, 255),
  ] as CFArray,
  locations: [0, 1]
)!

context.drawLinearGradient(
  gradient,
  start: CGPoint(x: 0, y: canvasSize / 2),
  end: CGPoint(x: canvasSize, y: canvasSize / 2),
  options: []
)

let iconFont = CTFontCreateWithGraphicsFont(graphicsFont, 500, nil, nil)
var character = materialBoltRounded
var glyph = CGGlyph()

guard CTFontGetGlyphsForCharacters(iconFont, &character, &glyph, 1), glyph != 0 else {
  fputs("Could not resolve Flutter's rounded bolt glyph.\n", stderr)
  exit(1)
}

var measuredGlyph = glyph
let bounds = CTFontGetBoundingRectsForGlyphs(
  iconFont,
  .default,
  &measuredGlyph,
  nil,
  1
)
var position = CGPoint(
  x: CGFloat(canvasSize) / 2 - bounds.midX,
  y: CGFloat(canvasSize) / 2 - bounds.midY
)

context.setFillColor(NSColor.white.cgColor)
CTFontDrawGlyphs(iconFont, &glyph, &position, 1, context)

guard let image = context.makeImage() else {
  fputs("Could not finish the app icon image.\n", stderr)
  exit(1)
}

let representation = NSBitmapImageRep(cgImage: image)
guard
  let png = representation.representation(
    using: .png,
    properties: [.compressionFactor: 1.0]
  )
else {
  fputs("Could not encode the app icon as PNG.\n", stderr)
  exit(1)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(
  at: outputURL.deletingLastPathComponent(),
  withIntermediateDirectories: true
)
try png.write(to: outputURL, options: .atomic)
