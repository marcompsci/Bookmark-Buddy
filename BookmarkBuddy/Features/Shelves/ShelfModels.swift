// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Public shareable shelves
//
// Every reader can publish a shelf like Omari's Digital Library: a handle, a short bio,
// and up to 50 books drawn as spines. Public shelves open from bookmarkbuddy://shelf/<handle>.

struct ReaderShelf: Codable, Hashable, Sendable {
    var handle: String
    var displayName: String
    var bio: String
    var isPublic: Bool

    static let empty = ReaderShelf(handle: "", displayName: "", bio: "", isPublic: false)

    enum Limits {
        static let handle = 24
        static let displayName = 40
        static let bio = 160
        static let books = 50
    }

    /// 3–24 characters: lowercase letters, numbers, underscores.
    static func isValidHandle(_ handle: String) -> Bool {
        handle.range(of: "^[a-z0-9_]{3,24}$", options: .regularExpression) != nil
    }

    static func normalizedHandle(_ raw: String) -> String {
        String(raw.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .unicodeScalars.filter { $0.isASCII }.map(Character.init).prefix(Limits.handle))
    }

    var shareURL: URL? {
        guard Self.isValidHandle(handle) else { return nil }
        return URL(string: "bookmarkbuddy://shelf/\(handle)")
    }
}

struct ShelfEntry: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var author: String
    var note: String
    var colorIndex: Int
    var position: Int

    /// Draws with the same spine renderer as the Digital Library.
    var spineBook: DLBook {
        let palette = DLRecommendation.palette[min(max(colorIndex, 0), DLRecommendation.palette.count - 1)]
        let styles: [DLSpine.FontStyle] = [.serif, .cond, .heavy, .classic, .display]
        let decorations: [DLSpine.Decoration] = [.bands, .block, .foot, .rule, .dot]
        // Stable across launches (hashValue isn't), so a book always gets the same spine.
        let stable = title.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return DLBook(
            id: id.uuidString, title: title, subtitle: nil, author: author, authorNote: nil,
            year: 0, firstPublished: nil, genre: "", publisher: "",
            spine: DLSpine(
                title: title, author: author,
                background: palette.background, text: palette.text, accent: palette.text,
                fontStyle: styles[stable % styles.count],
                decoration: decorations[(stable / 5) % decorations.count],
                widthPt: Double(30 + (stable % 34)), heightPt: Double(250 + (stable % 70)),
                tilted: false
            ),
            coverMotif: "rule", description: note, quotes: [], panels: DLPanels(whyThisMatters: nil, briefSummary: nil, briefInvestmentStrategies: nil)
        )
    }
}

struct ShelfSnapshot: Hashable, Sendable {
    var shelf: ReaderShelf
    var entries: [ShelfEntry]
}

enum ShelfError: LocalizedError {
    case invalidHandle
    case handleTaken
    case missingTitleOrAuthor
    case full
    case notSignedIn
    case notSetUp
    case server

    var errorDescription: String? {
        switch self {
        case .invalidHandle: "Handles are 3–24 characters: lowercase letters, numbers and underscores."
        case .handleTaken: "That handle is taken. Try another."
        case .missingTitleOrAuthor: "Add both the title and the author."
        case .full: "Your shelf holds up to 50 books."
        case .notSignedIn: "Sign in to save your shelf."
        case .notSetUp: "Shelf sharing isn't switched on for this server yet."
        case .server: "Couldn't save that right now. Try again in a moment."
        }
    }
}
