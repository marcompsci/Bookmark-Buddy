// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

enum ReadingState: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case reading, wantToRead, finished

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .reading: "Reading"
        case .wantToRead: "Want to Read"
        case .finished: "Finished"
        }
    }
}

/// Original motifs for generated cover art. No real cover assets are used anywhere.
enum CoverMotif: String, Codable, CaseIterable, Hashable, Sendable {
    case harbor, orbit, garden, lantern, bridge, compass
    case ledger, sprout, moon, bulb, breeze, heart, portrait, sun

    var symbol: String {
        switch self {
        case .harbor: "water.waves"
        case .orbit: "moon.stars.fill"
        case .garden: "leaf.fill"
        case .lantern: "flame.fill"
        case .bridge: "building.columns.fill"
        case .compass: "location.north.circle.fill"
        case .ledger: "chart.line.uptrend.xyaxis"
        case .sprout: "leaf.arrow.triangle.circlepath"
        case .moon: "moon.haze.fill"
        case .bulb: "lightbulb.fill"
        case .breeze: "wind"
        case .heart: "heart.fill"
        case .portrait: "person.fill"
        case .sun: "sun.max.fill"
        }
    }
}

struct CoverStyle: Codable, Hashable, Sendable {
    var paletteIndex: Int
    var motif: CoverMotif
}

struct BookCharacter: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var role: String
    /// Characters introduced after the reader's current chapter are hidden to avoid spoilers.
    var introducedInChapter: Int
}

/// Where a book's data came from. Drives the labels shown on covers and detail screens.
enum BookSource: String, Codable, Hashable, Sendable {
    /// Invented demo title with original fictional plot content.
    case demo
    /// A real book from the owner's personal shelf. Metadata only (title, author, genre);
    /// no summaries, quotes or cover images are copied.
    case personalShelf

    var label: String {
        switch self {
        case .demo: "Fictional demo title"
        case .personalShelf: "From your shelf · metadata only"
        }
    }
}

struct Book: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var author: String
    var genres: [Genre]
    var pageCount: Int
    var chapterCount: Int
    /// Setup only. Must never reveal plot resolution.
    var premise: String
    var cover: CoverStyle
    var characters: [BookCharacter]
    /// True for invented demo titles; false for real books imported from the personal shelf.
    var isDemoContent: Bool = true
    var source: BookSource = .demo

    /// Chapter/page structure is known only for demo titles until licensed metadata is connected.
    var hasChapterData: Bool { chapterCount > 0 }
}

struct ReadingProgress: Codable, Identifiable, Hashable, Sendable {
    var id: UUID { bookID }
    var bookID: UUID
    var state: ReadingState
    var currentChapter: Int
    var pagesRead: Int
    var startedAt: Date?
    var finishedAt: Date?
    /// 0...1 — how well the reader still remembers a finished book (drives the Memory Garden).
    var memoryStrength: Double

    func fractionComplete(of book: Book) -> Double {
        if state == .finished { return 1 }
        guard book.pageCount > 0 else { return 0 }
        return min(1, max(0, Double(pagesRead) / Double(book.pageCount)))
    }
}

/// Convenience pairing used throughout the UI.
struct BookWithProgress: Identifiable, Hashable, Sendable {
    var book: Book
    var progress: ReadingProgress?

    var id: UUID { book.id }
    var state: ReadingState { progress?.state ?? .wantToRead }
    var fraction: Double { progress?.fractionComplete(of: book) ?? 0 }
}
