// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

enum AppTab: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case home, squad, play, library, explore, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .squad: "Squad"
        case .play: "Play"
        case .library: "Library"
        case .explore: "Explore"
        case .profile: "Profile"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .squad: "person.3.fill"
        case .play: "gamecontroller.fill"
        case .library: "books.vertical.fill"
        case .explore: "safari.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

/// Push destinations inside a tab's NavigationStack.
enum AppRoute: Hashable, Sendable {
    case bookDetail(UUID)
    /// `bookID` is nil for library-wide quizzes such as Title & Author.
    case quiz(bookID: UUID?, mode: QuizMode)
    case eventDetail(UUID)
    case privacySafety
    /// Public shelf view for a given Explore user.
    case userPublicShelf(ExploreUser)
    /// Community book recommendations shelf.
    case recommendedShelf
}

/// Modal flows presented from anywhere (by views, Pip, or App Intents).
enum AppSheet: Identifiable, Hashable, Sendable {
    case createEvent(EventType?)
    case buddyRead(bookID: UUID?)
    /// Pip's chat. `bookID` scopes the conversation to one book ("Ask Pip about this book").
    case pip(bookID: UUID?)
    /// Recommend a book to the community shelf.
    case recommendBook

    var id: String {
        switch self {
        case .createEvent(let type): "createEvent-\(type?.rawValue ?? "none")"
        case .buddyRead(let bookID): "buddyRead-\(bookID?.uuidString ?? "none")"
        case .pip(let bookID): "pip-\(bookID?.uuidString ?? "general")"
        case .recommendBook: "recommendBook"
        }
    }
}

enum StorageKeys {
    static let hasCompletedOnboarding = "bb.hasCompletedOnboarding"
    static let pipPosition = "bb.pipPosition"
    static let refreshReminderEnabled = "bb.refreshReminderEnabled"
    static let refreshReminderHour = "bb.refreshReminderHour"
}
