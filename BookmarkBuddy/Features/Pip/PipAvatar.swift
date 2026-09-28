// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Pip, the book sprite: a glowing orb with expressive eyes and a gold bookmark tail.
/// Built entirely from SwiftUI shapes. Idle bob + blink stop when Reduce Motion is on.
///
/// To rename the companion, change `PipIdentity.name` — the drawing doesn't depend on it.
enum PipIdentity {
    static let name = "Pip"
    static let accessibilityButtonLabel = "Open \(name), your reading companion"
}

struct PipAvatar: View {
    enum Mood: Hashable {
        case idle, happy, thinking, cheering
    }

    var size: CGFloat = 56
    var mood: Mood = .idle
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isAnimating: Bool { animated && !reduceMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isAnimating)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let bob: CGFloat = isAnimating ? CGFloat(sin(time * 2.2)) * size * 0.04 : 0
            let tailSwing: Double = isAnimating ? sin(time * 1.6) * 6 : 0
            let blinking = isAnimating && time.truncatingRemainder(dividingBy: 4.2) < 0.14
            PipFigure(size: size, mood: mood, eyesClosed: blinking, tailAngle: 18 + tailSwing)
                .offset(y: bob)
        }
        .frame(width: size * 1.3, height: size * 1.45)
        .accessibilityHidden(true)
    }
}

private struct PipFigure: View {
    let size: CGFloat
    let mood: PipAvatar.Mood
    let eyesClosed: Bool
    let tailAngle: Double

    private let bodyLight = Color(red: 0.88, green: 0.85, blue: 0.99)
    private let bodyDark = Color(red: 0.50, green: 0.43, blue: 0.78)

    var body: some View {
        ZStack {
            // Bookmark tail
            BookmarkRibbon()
                .fill(
                    LinearGradient(
                        colors: [Theme.Palette.gold, Color(red: 0.78, green: 0.55, blue: 0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.22, height: size * 0.5)
                .rotationEffect(.degrees(tailAngle), anchor: .top)
                .offset(x: size * 0.2, y: size * 0.42)

            // Soft glow
            Circle()
                .fill(Theme.Palette.lavender.opacity(0.35))
                .frame(width: size * 1.15, height: size * 1.15)
                .blur(radius: size * 0.12)

            // Body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [bodyLight, Theme.Palette.lavender, bodyDark],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: size * 0.02,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: max(1, size * 0.02))
                )

            // Page-corner tuft
            RoundedRectangle(cornerRadius: size * 0.03)
                .fill(Theme.Palette.parchment)
                .frame(width: size * 0.16, height: size * 0.2)
                .rotationEffect(.degrees(-18))
                .offset(x: -size * 0.12, y: -size * 0.5)

            face
                .offset(y: size * 0.02)
        }
    }

    private var face: some View {
        VStack(spacing: size * 0.06) {
            HStack(spacing: size * 0.18) {
                eye
                eye
            }
            ZStack {
                mouth
                HStack(spacing: size * 0.42) {
                    cheek
                    cheek
                }
                .offset(y: -size * 0.03)
            }
        }
    }

    private var eye: some View {
        ZStack(alignment: .topTrailing) {
            Capsule()
                .fill(Theme.Palette.ink)
                .frame(width: size * 0.12, height: eyesClosed ? size * 0.025 : eyeHeight)
            if !eyesClosed {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.045, height: size * 0.045)
                    .offset(x: -size * 0.015, y: size * 0.02)
            }
        }
        .frame(height: size * 0.18)
    }

    private var eyeHeight: CGFloat {
        switch mood {
        case .thinking: size * 0.12
        case .cheering: size * 0.10
        default: size * 0.17
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .thinking:
            Circle()
                .fill(Theme.Palette.ink)
                .frame(width: size * 0.07, height: size * 0.07)
        case .happy, .cheering:
            SmileShape(depth: 0.9)
                .fill(Theme.Palette.ink)
                .frame(width: size * 0.22, height: size * 0.1)
        case .idle:
            SmileShape(depth: 0.5)
                .stroke(Theme.Palette.ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.035), lineCap: .round))
                .frame(width: size * 0.16, height: size * 0.06)
        }
    }

    private var cheek: some View {
        Circle()
            .fill(Theme.Palette.gold.opacity(0.45))
            .frame(width: size * 0.09, height: size * 0.09)
    }
}

/// Ribbon with a V-notch at the bottom, like a bookmark.
struct BookmarkRibbon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.55))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A curved smile. `depth` 0...1 controls how deep the curve is.
struct SmileShape: Shape {
    var depth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2 * depth)
        )
        return path
    }
}

#Preview {
    HStack(spacing: 24) {
        PipAvatar(size: 56, mood: .idle)
        PipAvatar(size: 56, mood: .happy)
        PipAvatar(size: 56, mood: .thinking)
        PipAvatar(size: 96, mood: .cheering)
    }
    .padding()
    .background(InkBackground())
}
