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
// BACKGROUND — multi-layer radial gradient
// 多层径向渐变叠加，边缘有深度，中心明亮
// ═══════════════════════════════════════

// Layer 0: base fill — deep plum
ctx.setFillColor(CGColor(srgbRed: 0.18, green: 0.06, blue: 0.30, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: S, height: S))

// Layer 1: bottom-right — warm amber bloom
let g1 = CGGradient(colorSpace: cs, colorComponents: [
    0.96, 0.58, 0.16, 0.95,
    0.96, 0.58, 0.16, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(g1,
    startCenter: CGPoint(x: S * 0.88, y: S * 0.90), startRadius: 0,
    endCenter: CGPoint(x: S * 0.88, y: S * 0.90), endRadius: S * 0.80, options: [])

// Layer 2: center — warm coral/rose
let g2 = CGGradient(colorSpace: cs, colorComponents: [
    0.92, 0.32, 0.38, 0.80,
    0.92, 0.32, 0.38, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(g2,
    startCenter: CGPoint(x: S * 0.55, y: S * 0.55), startRadius: 0,
    endCenter: CGPoint(x: S * 0.55, y: S * 0.55), endRadius: S * 0.60, options: [])

// Layer 3: top-left — deep violet anchor
let g3 = CGGradient(colorSpace: cs, colorComponents: [
    0.36, 0.10, 0.62, 0.75,
    0.36, 0.10, 0.62, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(g3,
    startCenter: CGPoint(x: S * 0.10, y: S * 0.08), startRadius: 0,
    endCenter: CGPoint(x: S * 0.10, y: S * 0.08), endRadius: S * 0.65, options: [])

// Layer 4: upper-center brightness lift
let g4 = CGGradient(colorSpace: cs, colorComponents: [
    0.95, 0.45, 0.42, 0.35,
    0.95, 0.45, 0.42, 0.0,
], locations: [0, 1], count: 2)!
ctx.drawRadialGradient(g4,
    startCenter: CGPoint(x: S * 0.40, y: S * 0.32), startRadius: 0,
    endCenter: CGPoint(x: S * 0.40, y: S * 0.32), endRadius: S * 0.40, options: [])

// ═══════════════════════════════════════
// WAVEFORM — filled organic shape
// 连续填充波形，不是竖条也不是线条
// ═══════════════════════════════════════

let cy: CGFloat = 505

// Upper contour points (x, y_offset_above_center)
// Tapers at edges, peaks in the middle
let upper: [(CGFloat, CGFloat)] = [
    (90, 0), (180, 28), (260, 68), (340, 120),
    (420, 158), (490, 172), (540, 170), (600, 150),
    (670, 115), (740, 70), (820, 32), (934, 0),
]

// Build filled shape: upper contour → lower contour (mirrored)
let wave = CGMutablePath()
// Start at left edge
wave.move(to: CGPoint(x: upper[0].0, y: cy))

// Upper contour (smooth curve through points)
for (x, off) in upper {
    wave.addLine(to: CGPoint(x: x, y: cy - off))
}
// Right edge
wave.addLine(to: CGPoint(x: upper.last!.0, y: cy))
// Lower contour (mirrored, reversed)
for (x, off) in upper.reversed() {
    wave.addLine(to: CGPoint(x: x, y: cy + off))
}
wave.closeSubpath()

// Smoothed version: convert to stroked outline for smooth edges
let smoothWave = wave.copy(strokingWithWidth: 2, lineCap: .round, lineJoin: .round, miterLimit: 10)

// Glow behind
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 6), blur: 35,
              color: CGColor(srgbRed: 0.04, green: 0.01, blue: 0.10, alpha: 0.45))
ctx.addPath(wave)
ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.15))
ctx.fillPath()
ctx.restoreGState()

// Main shape — white gradient fill (brighter in center)
ctx.saveGState()
ctx.addPath(wave)
ctx.clip()
let waveGrad = CGGradient(colorSpace: cs, colorComponents: [
    1, 1, 1, 0.55,
    1, 1, 1, 0.95,
    1, 1, 1, 0.55,
], locations: [0, 0.5, 1], count: 3)!
ctx.drawLinearGradient(waveGrad,
    start: CGPoint(x: 90, y: cy),
    end: CGPoint(x: 934, y: cy), options: [])
ctx.restoreGState()

// ═══════════════════════════════════════
// INNER WAVE CUTOUT — voice texture
// 内部切出波纹线条，增加声波质感
// ═══════════════════════════════════════
let lineCount = 5
let lineGap: CGFloat = 22
let totalLineHeight = CGFloat(lineCount - 1) * lineGap

for i in 0..<lineCount {
    let lineY = cy - totalLineHeight / 2 + CGFloat(i) * lineGap
    let amplitude: CGFloat = 18 + CGFloat(i % 2 == 0 ? 8 : -4)

    let linePath = CGMutablePath()
    linePath.move(to: CGPoint(x: 180, y: lineY))
    linePath.addCurve(
        to: CGPoint(x: 512, y: lineY - amplitude),
        control1: CGPoint(x: 290, y: lineY + amplitude * 0.6),
        control2: CGPoint(x: 400, y: lineY - amplitude))
    linePath.addCurve(
        to: CGPoint(x: 844, y: lineY),
        control1: CGPoint(x: 624, y: lineY - amplitude),
        control2: CGPoint(x: 734, y: lineY + amplitude * 0.6))

    ctx.saveGState()
    ctx.addPath(wave)
    ctx.clip()
    ctx.addPath(linePath)
    let lineAlpha: CGFloat = 0.12 + (i == 2 ? 0.08 : 0)
    ctx.setStrokeColor(CGColor(srgbRed: 0.20, green: 0.08, blue: 0.35, alpha: lineAlpha))
    ctx.setLineWidth(2.5)
    ctx.setLineCap(.round)
    ctx.strokePath()
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
