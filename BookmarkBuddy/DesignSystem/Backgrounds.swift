// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Deep-ink backdrop with soft color glows and a subtle paper grain, drawn entirely in SwiftUI.
struct InkBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Palette.ink, Theme.Palette.inkRaised.opacity(0.9), Theme.Palette.ink],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Theme.Palette.lavender.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            RadialGradient(
                colors: [Theme.Palette.gold.opacity(0.08), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 380
            )

            PaperGrain()
                .opacity(0.5)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Deterministic speckle texture. Uses a seeded generator so it never "shimmers" between renders.
struct PaperGrain: View {
    var density: Int = 900

    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: 42)
            for _ in 0..<density {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let radius = CGFloat.random(in: 0.3...1.1, using: &generator)
                let alpha = Double.random(in: 0.02...0.07, using: &generator)
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(Theme.Palette.parchment.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// SplitMix64 — tiny, fast, deterministic.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#Preview {
    InkBackground()
}
