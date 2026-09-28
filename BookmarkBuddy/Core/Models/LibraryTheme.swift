// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import Observation

// MARK: - Spine display style

enum SpineDisplayStyle: String, CaseIterable, Identifiable, Sendable {
    case classic   // current: gradient with dark binding edge
    case minimal   // flat solid color, hairline border
    case vivid     // saturated gradient, white text pop

    var id: String { rawValue }
    var label: String {
        switch self {
        case .classic: "Classic"
        case .minimal: "Minimal"
        case .vivid:   "Vivid"
        }
    }
    var symbol: String {
        switch self {
        case .classic: "books.vertical.fill"
        case .minimal: "rectangle.portrait"
        case .vivid:   "paintbrush.fill"
        }
    }
}

// MARK: - Theme preset

struct ShelfThemePreset: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    // Shelf area background (behind the books)
    let shelfBackgroundColors: [Color]
    // Wooden ledge surface
    let woodTopColor: Color
    let woodBottomColor: Color
    // Text on the shelf
    let shelfLabelColor: Color
    let shelfSubLabelColor: Color
    // Spine rendering tweak
    let spineHighlightOpacity: Double
    // Whether background is light (affects chip/label contrast)
    let isLight: Bool

    static func == (lhs: ShelfThemePreset, rhs: ShelfThemePreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Accent color entry

struct AccentColorEntry: Identifiable, Sendable {
    let id: String
    let name: String
    let color: Color
    let onColor: Color   // text color drawn on top of this accent
}

// MARK: - All presets

enum LibraryThemeData {
    static let presets: [ShelfThemePreset] = [
        inkWorld, editorial, midnight, canopy, ember
    ]

    // ── 1. Ink World (default) ──────────────────────────────────────────────
    static let inkWorld = ShelfThemePreset(
        id: "inkWorld",
        name: "Ink World",
        emoji: "🌙",
        description: "Deep navy, warm wood, parchment text",
        shelfBackgroundColors: [
            Color(red: 0.067, green: 0.078, blue: 0.169),
            Color(red: 0.106, green: 0.122, blue: 0.239)
        ],
        woodTopColor:    Color(red: 0.40, green: 0.30, blue: 0.18),
        woodBottomColor: Color(red: 0.24, green: 0.17, blue: 0.10),
        shelfLabelColor:    Color(red: 0.953, green: 0.914, blue: 0.824),
        shelfSubLabelColor: Color(red: 0.953, green: 0.914, blue: 0.824).opacity(0.65),
        spineHighlightOpacity: 0.38,
        isLight: false
    )

    // ── 2. Editorial (warm paper — from the Bookmark Buddyy spec) ───────────
    static let editorial = ShelfThemePreset(
        id: "editorial",
        name: "Editorial",
        emoji: "📰",
        description: "Warm cream, oak shelves, quiet and literary",
        shelfBackgroundColors: [
            Color(hex: "#ECEAE5"),
            Color(hex: "#E3E0D9")
        ],
        woodTopColor:    Color(hex: "#C2B89A"),
        woodBottomColor: Color(hex: "#A89872"),
        shelfLabelColor:    Color(hex: "#24221E"),
        shelfSubLabelColor: Color(hex: "#5C5850"),
        spineHighlightOpacity: 0.20,
        isLight: true
    )

    // ── 3. Midnight ──────────────────────────────────────────────────────────
    static let midnight = ShelfThemePreset(
        id: "midnight",
        name: "Midnight",
        emoji: "⭐",
        description: "True black, silver, ultra-minimal",
        shelfBackgroundColors: [
            Color(red: 0.04, green: 0.04, blue: 0.05),
            Color(red: 0.08, green: 0.07, blue: 0.09)
        ],
        woodTopColor:    Color(red: 0.18, green: 0.15, blue: 0.13),
        woodBottomColor: Color(red: 0.10, green: 0.08, blue: 0.07),
        shelfLabelColor:    Color(red: 0.92, green: 0.90, blue: 0.88),
        shelfSubLabelColor: Color(red: 0.55, green: 0.52, blue: 0.50),
        spineHighlightOpacity: 0.28,
        isLight: false
    )

    // ── 4. Canopy ────────────────────────────────────────────────────────────
    static let canopy = ShelfThemePreset(
        id: "canopy",
        name: "Canopy",
        emoji: "🌿",
        description: "Deep forest green, gold accents, earthy",
        shelfBackgroundColors: [
            Color(red: 0.07, green: 0.22, blue: 0.14),
            Color(red: 0.04, green: 0.13, blue: 0.08)
        ],
        woodTopColor:    Color(red: 0.22, green: 0.34, blue: 0.18),
        woodBottomColor: Color(red: 0.14, green: 0.22, blue: 0.11),
        shelfLabelColor:    Color(red: 0.88, green: 0.97, blue: 0.88),
        shelfSubLabelColor: Color(red: 0.58, green: 0.80, blue: 0.62),
        spineHighlightOpacity: 0.30,
        isLight: false
    )

    // ── 5. Ember ─────────────────────────────────────────────────────────────
    static let ember = ShelfThemePreset(
        id: "ember",
        name: "Ember",
        emoji: "🔥",
        description: "Warm terracotta, mahogany, amber glow",
        shelfBackgroundColors: [
            Color(red: 0.20, green: 0.09, blue: 0.04),
            Color(red: 0.13, green: 0.06, blue: 0.02)
        ],
        woodTopColor:    Color(red: 0.44, green: 0.22, blue: 0.10),
        woodBottomColor: Color(red: 0.28, green: 0.13, blue: 0.05),
        shelfLabelColor:    Color(red: 0.97, green: 0.88, blue: 0.76),
        shelfSubLabelColor: Color(red: 0.82, green: 0.65, blue: 0.48),
        spineHighlightOpacity: 0.36,
        isLight: false
    )

    // ── Accent color swatches ─────────────────────────────────────────────────
    static let accentColors: [AccentColorEntry] = [
        AccentColorEntry(id: "gold",       name: "Gold",       color: Color(hex: "#E3B85C"), onColor: Color(hex: "#1A1200")),
        AccentColorEntry(id: "bark",       name: "Bark",       color: Color(hex: "#8A5634"), onColor: .white),
        AccentColorEntry(id: "lavender",   name: "Lavender",   color: Color(hex: "#B8A9E3"), onColor: Color(hex: "#1A1233")),
        AccentColorEntry(id: "sage",       name: "Sage",       color: Color(hex: "#7CC29A"), onColor: Color(hex: "#0A2015")),
        AccentColorEntry(id: "terra",      name: "Terra",      color: Color(hex: "#D09A70"), onColor: Color(hex: "#2A1200")),
        AccentColorEntry(id: "slate",      name: "Slate",      color: Color(hex: "#5B7FA6"), onColor: .white),
        AccentColorEntry(id: "crimson",    name: "Crimson",    color: Color(hex: "#C4232B"), onColor: .white),
        AccentColorEntry(id: "pistachio",  name: "Pistachio",  color: Color(hex: "#A8C97A"), onColor: Color(hex: "#1A2A00"))
    ]
}

// MARK: - Observable store

/// Persists and exposes the user's current library customization choices.
/// Injected into the environment; views read with `@Environment(LibraryCustomization.self)`.
@Observable
final class LibraryCustomization {
    // Use backing vars so we can persist on every change.
    var themeID: String = UserDefaults.standard.string(forKey: "bb.shelfThemeID") ?? "inkWorld" {
        didSet { UserDefaults.standard.set(themeID, forKey: "bb.shelfThemeID") }
    }
    var accentColorID: String = UserDefaults.standard.string(forKey: "bb.shelfAccentID") ?? "gold" {
        didSet { UserDefaults.standard.set(accentColorID, forKey: "bb.shelfAccentID") }
    }
    var spineStyle: SpineDisplayStyle = {
        SpineDisplayStyle(rawValue: UserDefaults.standard.string(forKey: "bb.spineStyle") ?? "") ?? .classic
    }() {
        didSet { UserDefaults.standard.set(spineStyle.rawValue, forKey: "bb.spineStyle") }
    }

    var activeTheme: ShelfThemePreset {
        LibraryThemeData.presets.first { $0.id == themeID } ?? LibraryThemeData.inkWorld
    }
    var activeAccent: AccentColorEntry {
        LibraryThemeData.accentColors.first { $0.id == accentColorID } ?? LibraryThemeData.accentColors[0]
    }
}
