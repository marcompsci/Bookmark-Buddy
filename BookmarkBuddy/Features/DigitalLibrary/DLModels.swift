// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Omari's Digital Library
//
// The books from Omari's Digital Library website, bundled as Resources/DigitalLibraryBooks.json.
// Spines and covers are drawn in code from this data — no real cover art is embedded.

struct DLBook: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let author: String
    let authorNote: String?
    let year: Int
    let firstPublished: Int?
    let genre: String
    let publisher: String
    let spine: DLSpine
    let coverMotif: String
    let description: String
    let quotes: [DLQuote]
    let panels: DLPanels

    /// "Title by Author", for VoiceOver.
    var accessibilityName: String { "\(title) by \(author)" }

    /// Author last name, used for sorting ("García & Miralles" → "García").
    var authorSortKey: String {
        let first = author.components(separatedBy: CharacterSet(charactersIn: "&,")).first ?? author
        return (first.split(separator: " ").last.map(String.init) ?? first).lowercased()
    }

    /// Title without a leading "The ", for sorting.
    var titleSortKey: String {
        let lower = title.lowercased()
        return lower.hasPrefix("the ") ? String(lower.dropFirst(4)) : lower
    }
}

struct DLSpine: Codable, Hashable, Sendable {
    enum FontStyle: String, Codable, Sendable { case serif, cond, heavy, classic, display }
    enum Decoration: String, Codable, Sendable { case bands, block, foot, rule, dot }

    let title: String
    let author: String
    let background: String
    let text: String
    let accent: String
    let fontStyle: FontStyle
    let decoration: Decoration
    let widthPt: Double
    let heightPt: Double
    let tilted: Bool

    var backgroundColor: Color { Color(hex: background) }
    var textColor: Color { Color(hex: text) }
    var accentColor: Color { Color(hex: accent) }

    func titleFont(size: CGFloat) -> Font {
        switch fontStyle {
        case .serif: .system(size: size, weight: .heavy, design: .serif)
        case .cond: .system(size: size, weight: .semibold).width(.condensed)
        case .heavy: .system(size: size, weight: .black)
        case .classic: .system(size: size, weight: .regular, design: .serif)
        case .display: .system(size: size, weight: .medium, design: .serif).italic()
        }
    }

    /// Condensed and heavy spines are set in capitals, like the website.
    var usesUppercase: Bool { fontStyle == .cond || fontStyle == .heavy }
}

struct DLQuote: Codable, Hashable, Sendable {
    let text: String
    let why: String?
}

struct DLPanels: Codable, Hashable, Sendable {
    let whyThisMatters: [DLBlock]?
    let briefSummary: [DLBlock]?
    let briefInvestmentStrategies: [DLBlock]?

    var available: [DLPanel] {
        let all: [(DLPanelKind, [DLBlock]?)] = [
            (.whyThisMatters, whyThisMatters),
            (.briefSummary, briefSummary),
            (.briefInvestmentStrategies, briefInvestmentStrategies)
        ]
        return all.compactMap { pair -> DLPanel? in
            guard let blocks = pair.1, !blocks.isEmpty else { return nil }
            return DLPanel(kind: pair.0, blocks: blocks)
        }
    }
}

struct DLPanel: Identifiable, Hashable, Sendable {
    let kind: DLPanelKind
    let blocks: [DLBlock]
    var id: DLPanelKind { kind }
}

enum DLPanelKind: String, Hashable, Sendable {
    case whyThisMatters, briefSummary, briefInvestmentStrategies

    var title: String {
        switch self {
        case .whyThisMatters: "Why This Matters"
        case .briefSummary: "Brief Summary"
        case .briefInvestmentStrategies: "Brief Investment Strategies"
        }
    }
}

/// One block of panel content. Text may contain **bold** and *italic* markdown (Omari's own copy).
struct DLBlock: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case heading, subheading, paragraph, bullet, quoteHeading, tableHeader, row
    }
    let kind: Kind
    let text: String
    let detail: String?
}

// MARK: - Catalog

enum DLCatalog {
    /// All books, in shelf order. Loaded once from the bundle.
    static let books: [DLBook] = load()

    static var genres: [String] {
        var seen = Set<String>()
        return books.map(\.genre).filter { seen.insert($0).inserted }
    }

    static func count(in genre: String) -> Int {
        books.filter { $0.genre == genre }.count
    }

    static func book(id: String) -> DLBook? {
        books.first { $0.id == id }
    }

    private static func load() -> [DLBook] {
        guard let url = Bundle.main.url(forResource: "DigitalLibraryBooks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DLBook].self, from: data) else {
            assertionFailure("DigitalLibraryBooks.json is missing from the app bundle.")
            return []
        }
        return decoded.map(enriched)
    }

    /// Fills in quotes (with their "why it is powerful" notes) from the in-app `BookCatalog`
    /// when the website data has none or fewer notes.
    private static func enriched(_ book: DLBook) -> DLBook {
        guard let entry = BookCatalog.entry(forTitle: book.title), !entry.quotes.isEmpty else { return book }
        let catalogQuotes = entry.quotes.map { DLQuote(text: $0.text, why: $0.note) }
        let existingNotes = book.quotes.filter { $0.why != nil }.count
        let catalogNotes = catalogQuotes.filter { $0.why != nil }.count
        guard book.quotes.isEmpty || catalogNotes > existingNotes else { return book }
        return DLBook(
            id: book.id, title: book.title, subtitle: book.subtitle, author: book.author,
            authorNote: book.authorNote, year: book.year, firstPublished: book.firstPublished,
            genre: book.genre, publisher: book.publisher, spine: book.spine,
            coverMotif: book.coverMotif, description: book.description,
            quotes: catalogQuotes, panels: book.panels
        )
    }
}

// MARK: - Recommendations to Omari

/// A book a reader recommended to Omari. Shown flat on the floating shelf.
struct DLRecommendation: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var author: String
    var from: String
    var note: String
    var colorIndex: Int
    var createdAt: Date

    /// The eight spine colors from the website, each with a readable text color.
    static let palette: [(background: String, text: String)] = [
        ("#7A2E2E", "#F4EFE2"), ("#1F3B5A", "#F1E7CF"), ("#2F5D46", "#F4EFE2"), ("#C9A24A", "#2B1A0E"),
        ("#E9E3D6", "#1E1E1E"), ("#4A3F6B", "#F1E7CF"), ("#B5562E", "#FBFAF5"), ("#1E1E1E", "#EDE9E1")
    ]

    var backgroundColor: Color { Color(hex: Self.palette[safeIndex].background) }
    var textColor: Color { Color(hex: Self.palette[safeIndex].text) }
    private var safeIndex: Int { min(max(colorIndex, 0), Self.palette.count - 1) }

    enum Limits {
        static let title = 90
        static let author = 60
        static let from = 40
        static let note = 280
    }
}
