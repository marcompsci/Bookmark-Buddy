// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Genres offered during onboarding and used for recommendations.
enum Genre: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case mystery, romance, sciFi, fantasy, literaryFiction, nonfiction, biography, thriller, history, youngAdult
    // Shelf categories imported from the personal Digital Library.
    case fiction, finance, selfGrowth, memoir, horror, ideas, mindfulness, health

    var id: String { rawValue }

    /// The ten genres offered during onboarding.
    static let onboardingCases: [Genre] = [
        .mystery, .romance, .sciFi, .fantasy, .literaryFiction,
        .nonfiction, .biography, .thriller, .history, .youngAdult
    ]

    var displayName: String {
        switch self {
        case .mystery: "Mystery"
        case .romance: "Romance"
        case .sciFi: "Sci-Fi"
        case .fantasy: "Fantasy"
        case .literaryFiction: "Literary Fiction"
        case .nonfiction: "Nonfiction"
        case .biography: "Biography"
        case .thriller: "Thriller"
        case .history: "History"
        case .youngAdult: "Young Adult"
        case .fiction: "Fiction"
        case .finance: "Finance"
        case .selfGrowth: "Self Growth"
        case .memoir: "Memoir"
        case .horror: "Horror"
        case .ideas: "Ideas"
        case .mindfulness: "Mindfulness"
        case .health: "Health"
        }
    }

    var symbol: String {
        switch self {
        case .mystery: "magnifyingglass"
        case .romance: "heart"
        case .sciFi: "sparkles"
        case .fantasy: "wand.and.stars"
        case .literaryFiction: "text.book.closed"
        case .nonfiction: "lightbulb"
        case .biography: "person.crop.square"
        case .thriller: "bolt"
        case .history: "building.columns"
        case .youngAdult: "star"
        case .fiction: "sun.max"
        case .finance: "dollarsign.circle"
        case .selfGrowth: "leaf.arrow.triangle.circlepath"
        case .memoir: "person.text.rectangle"
        case .horror: "moon.haze"
        case .ideas: "brain"
        case .mindfulness: "wind"
        case .health: "heart"
        }
    }
}

enum ReadingPace: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case relaxed, steady, sprinter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relaxed: "Relaxed"
        case .steady: "Steady"
        case .sprinter: "Sprinter"
        }
    }

    var detail: String {
        switch self {
        case .relaxed: "A few pages most days, no pressure."
        case .steady: "About a chapter a day."
        case .sprinter: "Big sessions when the mood strikes."
        }
    }

    var symbol: String {
        switch self {
        case .relaxed: "leaf"
        case .steady: "metronome"
        case .sprinter: "hare"
        }
    }
}

/// How much plot a person is comfortable seeing. Ordered from safest to most revealing.
enum SpoilerLevel: String, Codable, CaseIterable, Identifiable, Hashable, Comparable, Sendable {
    case premiseOnly, currentChapter, finishedBook, fullSpoilers

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .premiseOnly: 0
        case .currentChapter: 1
        case .finishedBook: 2
        case .fullSpoilers: 3
        }
    }

    static func < (lhs: SpoilerLevel, rhs: SpoilerLevel) -> Bool { lhs.rank < rhs.rank }

    var displayName: String {
        switch self {
        case .premiseOnly: "Premise only"
        case .currentChapter: "Current chapter"
        case .finishedBook: "Finished book"
        case .fullSpoilers: "Full spoilers"
        }
    }

    var detail: String {
        switch self {
        case .premiseOnly: "Only the setup — what's on the back cover. Nothing more."
        case .currentChapter: "Anything up to the chapter you're on."
        case .finishedBook: "Full recaps, but only for books you've finished."
        case .fullSpoilers: "Everything, any time. You like knowing the ending."
        }
    }

    var symbol: String {
        switch self {
        case .premiseOnly: "eye.slash"
        case .currentChapter: "bookmark"
        case .finishedBook: "checkmark.seal"
        case .fullSpoilers: "eye"
        }
    }
}

enum ActivityVisibility: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case privateOnly, squad, friends

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .privateOnly: "Private"
        case .squad: "Squad"
        case .friends: "Friends"
        }
    }
}

struct UserProfile: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var displayName: String
    var favoriteGenres: [Genre]
    var booksPerMonth: Int
    var pace: ReadingPace
    var spoilerLevel: SpoilerLevel
    var currentStreakDays: Int
    var squadPoints: Int
    var joinedSquadIDs: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        favoriteGenres: [Genre],
        booksPerMonth: Int,
        pace: ReadingPace,
        spoilerLevel: SpoilerLevel,
        currentStreakDays: Int = 0,
        squadPoints: Int = 0,
        joinedSquadIDs: [UUID] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.favoriteGenres = favoriteGenres
        self.booksPerMonth = booksPerMonth
        self.pace = pace
        self.spoilerLevel = spoilerLevel
        self.currentStreakDays = currentStreakDays
        self.squadPoints = squadPoints
        self.joinedSquadIDs = joinedSquadIDs
        self.createdAt = createdAt
    }

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }
}
