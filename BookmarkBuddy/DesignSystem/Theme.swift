// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Design tokens for Bookmark Buddy's "reading world" look:
/// deep ink backgrounds, parchment text, and lavender / forest / gold accents.
enum Theme {
    enum Palette {
        /// #11142B
        static let ink = Color(red: 0.067, green: 0.078, blue: 0.169)
        /// #1B1F3D — cards
        static let inkRaised = Color(red: 0.106, green: 0.122, blue: 0.239)
        /// #282D51 — pressed / selected surfaces
        static let inkHighlight = Color(red: 0.157, green: 0.176, blue: 0.318)
        /// #F3E9D2 — primary text on ink (≈14:1 contrast)
        static let parchment = Color(red: 0.953, green: 0.914, blue: 0.824)
        /// Secondary text on ink (still above 7:1)
        static let parchmentMuted = Color(red: 0.953, green: 0.914, blue: 0.824).opacity(0.78)
        /// #B8A9E3
        static let lavender = Color(red: 0.722, green: 0.663, blue: 0.890)
        /// #2F6B4C — fills only; pair with parchment text at headline weight
        static let forest = Color(red: 0.184, green: 0.420, blue: 0.298)
        /// #7CC29A — forest tint that reads as text on ink
        static let forestBright = Color(red: 0.486, green: 0.761, blue: 0.604)
        /// #E3B85C — primary actions (ink text on gold ≈9:1)
        static let gold = Color(red: 0.890, green: 0.722, blue: 0.361)
        /// Soft coral for destructive actions
        static let danger = Color(red: 0.937, green: 0.525, blue: 0.494)
        static let hairline = Color(red: 0.953, green: 0.914, blue: 0.824).opacity(0.10)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }

    /// Apple's minimum recommended hit target.
    static let minTapTarget: CGFloat = 44

    /// Gradients for generated book covers.
    static let coverGradients: [[Color]] = [
        [Color(red: 0.16, green: 0.33, blue: 0.45), Color(red: 0.07, green: 0.14, blue: 0.25)],   // harbor blue
        [Color(red: 0.45, green: 0.22, blue: 0.20), Color(red: 0.13, green: 0.08, blue: 0.16)],   // ember
        [Color(red: 0.22, green: 0.42, blue: 0.31), Color(red: 0.09, green: 0.19, blue: 0.15)],   // garden
        [Color(red: 0.55, green: 0.40, blue: 0.16), Color(red: 0.20, green: 0.12, blue: 0.10)],   // lantern
        [Color(red: 0.36, green: 0.30, blue: 0.52), Color(red: 0.13, green: 0.11, blue: 0.24)],   // dusk
        [Color(red: 0.42, green: 0.36, blue: 0.28), Color(red: 0.16, green: 0.14, blue: 0.13)]    // map
    ]

    static func coverGradient(_ index: Int) -> [Color] {
        coverGradients[abs(index) % coverGradients.count]
    }

    /// Generated avatar gradients, keyed by a stable seed.
    static let avatarGradients: [[Color]] = [
        [Palette.gold, Color(red: 0.85, green: 0.52, blue: 0.33)],
        [Palette.lavender, Color(red: 0.49, green: 0.42, blue: 0.78)],
        [Palette.forestBright, Color(red: 0.24, green: 0.52, blue: 0.47)],
        [Color(red: 0.93, green: 0.62, blue: 0.62), Color(red: 0.72, green: 0.36, blue: 0.48)],
        [Color(red: 0.55, green: 0.75, blue: 0.93), Color(red: 0.30, green: 0.45, blue: 0.78)],
        [Color(red: 0.95, green: 0.80, blue: 0.55), Color(red: 0.70, green: 0.55, blue: 0.35)]
    ]

    static func avatarGradient(seed: Int) -> [Color] {
        avatarGradients[abs(seed) % avatarGradients.count]
    }
}

extension Color {
    /// Initialize from a 6-digit hex string, e.g. `"#1D2B45"` or `"1D2B45"`.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    }
}

extension Font {
    /// Serif display type (New York) that scales with Dynamic Type.
    static let bbDisplay = Font.system(.largeTitle, design: .serif, weight: .semibold)
    static let bbTitle = Font.system(.title2, design: .serif, weight: .semibold)
    static let bbTitle3 = Font.system(.title3, design: .serif, weight: .semibold)
    static let bbHeadline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let bbBody = Font.system(.body)
    static let bbCallout = Font.system(.callout)
    static let bbCaption = Font.system(.caption, design: .rounded, weight: .medium)
}

// MARK: - Card surface

struct CardSurface: ViewModifier {
    var padding: CGFloat = Theme.Spacing.lg
    var fill: Color = Theme.Palette.inkRaised

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                            .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 8)
            )
    }
}

extension View {
    func bbCard(padding: CGFloat = Theme.Spacing.lg, fill: Color = Theme.Palette.inkRaised) -> some View {
        modifier(CardSurface(padding: padding, fill: fill))
    }

    /// Animates only when Reduce Motion is off.
    func bbAnimation<V: Equatable>(_ animation: Animation?, value: V, reduceMotion: Bool) -> some View {
        self.animation(reduceMotion ? nil : animation, value: value)
    }
}
