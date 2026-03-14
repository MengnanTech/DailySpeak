#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let S: CGFloat = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: Int(S), height: Int(S),
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError() }
ctx.translateBy(x: 0, y: S); ctx.scaleBy(x: 1, y: -1)

// ═══════════════════════════════════════
// BACKGROUND
// 用 App 自己的 Stage 配色：indigo → violet → pink
// 干净的对角线性渐变，不堆砌颜色
// ═══════════════════════════════════════
let bg = CGGradient(colorSpace: cs, colorComponents: [
    // #4338CA indigo (stage 7)
    0.263, 0.220, 0.792, 1,
    // #8B5CF6 violet (stage 3)
    0.545, 0.361, 0.965, 1,
    // #EC4899 pink (stage 4)
    0.925, 0.282, 0.600, 1,
], locations: [0, 0.52, 1], count: 3)!

ctx.drawLinearGradient(bg,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: S, y: S),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

// Subtle depth layers — same hue family, very gentle
// Upper-left: slightly cooler/deeper
let d1 = CGGradient(colorSpace: cs, colorComponents: [
    0.22, 0.16, 0.68, 0.30,
    0.22, 0.16, 0.68, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(d1,
    startCenter: CGPoint(x: S * 0.15, y: S * 0.12), startRadius: 0,
    endCenter: CGPoint(x: S * 0.15, y: S * 0.12), endRadius: S * 0.45, options: [])

// Lower-right: slightly warmer
let d2 = CGGradient(colorSpace: cs, colorComponents: [
    0.95, 0.35, 0.55, 0.18,
    0.95, 0.35, 0.55, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(d2,
    startCenter: CGPoint(x: S * 0.85, y: S * 0.88), startRadius: 0,
    endCenter: CGPoint(x: S * 0.85, y: S * 0.88), endRadius: S * 0.40, options: [])

// Center soft brightening
let d3 = CGGradient(colorSpace: cs, colorComponents: [
    1, 1, 1, 0.06,
    1, 1, 1, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(d3,
    startCenter: CGPoint(x: S * 0.48, y: S * 0.46), startRadius: 0,
    endCenter: CGPoint(x: S * 0.48, y: S * 0.46), endRadius: S * 0.35, options: [])

// ═══════════════════════════════════════
// ICON ELEMENT — 5 white rounded bars
// 简洁、居中、大小适中
// ═══════════════════════════════════════
let cx: CGFloat = 512
let cy: CGFloat = 500
let bw: CGFloat = 48
let br: CGFloat = 24
let gap: CGFloat = 24

struct Bar { let hh: CGFloat; let op: CGFloat }
let bars: [Bar] = [
    Bar(hh: 50,  op: 0.78),
    Bar(hh: 105, op: 0.86),
    Bar(hh: 150, op: 0.96),
    Bar(hh: 88,  op: 0.86),
    Bar(hh: 42,  op: 0.78),
]

let tw = CGFloat(bars.count) * bw + CGFloat(bars.count - 1) * gap
let sx = cx - tw / 2

for (i, bar) in bars.enumerated() {
    let x = sx + CGFloat(i) * (bw + gap)
    let y = cy - bar.hh
    let rect = CGRect(x: x, y: y, width: bw, height: bar.hh * 2)
    let path = CGPath(roundedRect: rect, cornerWidth: br, cornerHeight: br, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 14,
                  color: CGColor(srgbRed: 0.15, green: 0.05, blue: 0.30, alpha: 0.35))
    ctx.addPath(path)
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: bar.op))
    ctx.fillPath()
    ctx.restoreGState()
}

// ═══════════════════════════════════════
// EXPORT
// ═══════════════════════════════════════
guard let img = ctx.makeImage() else { fatalError() }
let rep = NSBitmapImageRep(cgImage: img)
rep.size = NSSize(width: Int(S), height: Int(S))
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError() }
let out = "DailySpeak/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
try! png.write(to: URL(fileURLWithPath: out))
try! png.write(to: URL(fileURLWithPath: "AppIcon_preview.png"))
print("Done → \(out)")
