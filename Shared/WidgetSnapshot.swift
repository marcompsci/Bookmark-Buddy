// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// What the home-screen widget shows. The app writes it to the shared App Group whenever
/// Today loads or an answer is recorded; the widget only reads it (widgets never compute).
/// Shared by the app and the widget extension.
struct WidgetSnapshot: Codable, Hashable {
    struct Plant: Codable, Hashable {
        var title: String
        var strength: Double
    }

    var question: String?
    var bookTitle: String?
    var answeredToday: Bool
    var streak: Int
    var level: Int
    var levelTitle: String
    var levelProgress: Double
    var xp: Int
    var plants: [Plant]
    var thirsty: Int
    var updatedAt: Date

    static let appGroup = "group.com.omaribell.BookmarkBuddy"
    private static let key = "bb.widget.snapshot.v1"
    /// Opens Today with the question showing.
    static let openURL = URL(string: "bookmarkbuddy://today/refresh")!

    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroup)?.set(data, forKey: Self.key)
    }

    static let placeholder = WidgetSnapshot(
        question: "Who wrote “The Glass Harbor”?",
        bookTitle: "The Glass Harbor",
        answeredToday: false,
        streak: 4,
        level: 3,
        levelTitle: "Sapling",
        levelProgress: 0.6,
        xp: 240,
        plants: [
            Plant(title: "The Glass Harbor", strength: 0.82),
            Plant(title: "Atomic Habits", strength: 0.46),
            Plant(title: "Dune", strength: 0.22),
        ],
        thirsty: 1,
        updatedAt: .now
    )

    /// Shown before the app has written anything (first install).
    static let empty = WidgetSnapshot(
        question: nil, bookTitle: nil, answeredToday: false, streak: 0, level: 1,
        levelTitle: "Seedling", levelProgress: 0, xp: 0, plants: [], thirsty: 0, updatedAt: .now
    )
}
