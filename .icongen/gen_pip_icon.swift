#!/usr/bin/env swift
import SwiftUI
import AppKit

// ── Theme colors (mirrors Theme.Palette) ──────────────────────────────────────
private let cInk       = Color(red: 0.051, green: 0.051, blue: 0.102)
private let cLavender  = Color(red: 0.56,  green: 0.50,  blue: 0.88)
private let cGold      = Color(red: 0.788, green: 0.655, blue: 0.302)
private let cParchment = Color(red: 0.953, green: 0.918, blue: 0.839)
private let cBodyLight = Color(red: 0.88,  green: 0.85,  blue: 0.99)
private let cBodyDark  = Color(red: 0.50,  green: 0.43,  blue: 0.78)

// ── Shapes (mirrors PipAvatar.swift) ─────────────────────────────────────────
struct BookmarkRibbon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.55))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct SmileShape: Shape {
    var depth: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to:      CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2 * depth)
        )
        return p
    }
}

// ── Icon view ─────────────────────────────────────────────────────────────────
struct PipIconView: View {
    // s = Pip body diameter; 440 leaves comfortable padding on 1024 canvas
    private let s: CGFloat = 440

    var body: some View {
        ZStack {
            // Dark gradient background
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.13, green: 0.11, blue: 0.24), location: 0.0),
                    .init(color: Color(red: 0.04, green: 0.034, blue: 0.09), location: 1.0),
                ]),
                center: .center, startRadius: 0, endRadius: 580
            )

            pip
        }
        .frame(width: 1024, height: 1024)
        .clipped()
    }

    // ── Pip figure (happy / smiling) ─────────────────────────────────────────
    private var pip: some View {
        ZStack {
            // Bookmark tail
            BookmarkRibbon()
                .fill(LinearGradient(
                    colors: [cGold, Color(red: 0.78, green: 0.55, blue: 0.22)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: s * 0.22, height: s * 0.5)
                .rotationEffect(.degrees(18), anchor: .top)
                .offset(x: s * 0.2, y: s * 0.42)

            // Glow rings (substitute for blur, renders reliably in ImageRenderer)
            Circle()
                .fill(cLavender.opacity(0.12))
                .frame(width: s * 1.55, height: s * 1.55)
            Circle()
                .fill(cLavender.opacity(0.18))
                .frame(width: s * 1.30, height: s * 1.30)
            Circle()
                .fill(cLavender.opacity(0.25))
                .frame(width: s * 1.12, height: s * 1.12)

            // Body
            Circle()
                .fill(RadialGradient(
                    colors: [cBodyLight, cLavender, cBodyDark],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: s * 0.02,
                    endRadius:   s * 0.65
                ))
                .frame(width: s, height: s)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: s * 0.022)
                )

            // Page-corner tuft (little parchment tab at top-left)
            RoundedRectangle(cornerRadius: s * 0.03)
                .fill(cParchment)
                .frame(width: s * 0.16, height: s * 0.2)
                .rotationEffect(.degrees(-18))
                .offset(x: -s * 0.12, y: -s * 0.5)

            // Face
            VStack(spacing: s * 0.06) {
                HStack(spacing: s * 0.18) { eyeView; eyeView }

                ZStack {
                    // Happy / big smile
                    SmileShape(depth: 0.9)
                        .fill(cInk)
                        .frame(width: s * 0.22, height: s * 0.1)

                    // Gold cheeks
                    HStack(spacing: s * 0.42) { cheekView; cheekView }
                        .offset(y: -s * 0.03)
                }
            }
            .offset(y: s * 0.02)
        }
        .frame(width: s * 1.3, height: s * 1.45)
    }

    private var eyeView: some View {
        ZStack(alignment: .topTrailing) {
            Capsule()
                .fill(cInk)
                .frame(width: s * 0.12, height: s * 0.10)  // happy / slightly squinted
            Circle()
                .fill(Color.white)
                .frame(width: s * 0.045, height: s * 0.045)
                .offset(x: -s * 0.015, y: s * 0.02)
        }
        .frame(height: s * 0.18)
    }

    private var cheekView: some View {
        Circle()
            .fill(cGold.opacity(0.55))
            .frame(width: s * 0.09, height: s * 0.09)
    }
}

// ── Render ────────────────────────────────────────────────────────────────────
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/PipIcon.png"

Task { @MainActor in
    let renderer = ImageRenderer(content: PipIconView())
    renderer.scale = 1.0
    guard let cgImage = renderer.cgImage else { print("render failed"); exit(1) }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let png = rep.representation(using: .png, properties: [:]) else { print("png failed"); exit(1) }
    try! png.write(to: URL(fileURLWithPath: outPath))
    print("Saved to \(outPath)")
    exit(0)
}
RunLoop.main.run()
