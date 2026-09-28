// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// PERSONAL SHELF
// Imported from the owner's "Digital Library" site (github.com/marcompsci/Omari-s-Digital-Libary).
// METADATA ONLY: title, author and shelf genre. Quotes, descriptions and cover images from
// that site are intentionally NOT copied. Covers are generated; summaries stay locked until
// licensed, source-linked metadata is connected.
//
// Assumption: books on the shelf are ones the owner has read, so they start as "Finished".
// Change `defaultState` below if that's wrong for a title.
// TODO(prod): Replace with the user's synced library + a licensed catalog API (ISBNs, page
// counts, chapter data, publisher-approved descriptions and cover art).
// ─────────────────────────────────────────────────────────────────────────────

enum PersonalShelf {
    private struct Entry {
        let title: String
        let author: String
        let genre: Genre
        var state: ReadingState = PersonalShelf.defaultState
    }

    static let defaultState: ReadingState = .finished

    private static let entries: [Entry] = [
        Entry(title: "The Intelligent Investor", author: "Benjamin Graham", genre: .finance),
        Entry(title: "Money Works: The Guide to Financial Literacy", author: "Abhijeet Kolapkar", genre: .finance),
        Entry(title: "The Let Them Theory", author: "Mel Robbins", genre: .selfGrowth),
        Entry(title: "Open", author: "Andre Agassi", genre: .memoir),
        Entry(title: "The Shining", author: "Stephen King", genre: .horror),
        Entry(title: "It", author: "Stephen King", genre: .horror),
        Entry(title: "David and Goliath", author: "Malcolm Gladwell", genre: .ideas),
        Entry(title: "The Tipping Point", author: "Malcolm Gladwell", genre: .ideas),
        Entry(title: "Outliers", author: "Malcolm Gladwell", genre: .ideas),
        Entry(title: "Atomic Habits", author: "James Clear", genre: .selfGrowth),
        Entry(title: "Don't Believe Everything You Think", author: "Joseph Nguyen", genre: .mindfulness),
        Entry(title: "Ikigai", author: "Francesc Miralles", genre: .mindfulness),
        Entry(title: "The Alchemist", author: "Paulo Coelho", genre: .fiction),
        Entry(title: "The Mountain Is You", author: "Brianna Wiest", genre: .selfGrowth),
        Entry(title: "The Art of Letting Go", author: "Lucas Hayes", genre: .selfGrowth),
        Entry(title: "Dare to Succeed", author: "Success Center", genre: .selfGrowth),
        Entry(title: "The Body Keeps the Score", author: "Bessel van der Kolk", genre: .health)
    ]

    private static func motif(for genre: Genre) -> CoverMotif {
        switch genre {
        case .finance: .ledger
        case .selfGrowth: .sprout
        case .horror: .moon
        case .ideas: .bulb
        case .mindfulness: .breeze
        case .health: .heart
        case .memoir, .biography: .portrait
        default: .sun
        }
    }

    static let books: [Book] = entries.enumerated().map { index, entry in
        Book(
            id: DemoData.id(800 + index),
            title: entry.title,
            author: entry.author,
            genres: [entry.genre],
            pageCount: 0,
            chapterCount: 0,
            premise: "On your shelf as a \(entry.genre.displayName.lowercased()) title by \(entry.author). A publisher-approved description will appear here once licensed metadata is connected.",
            cover: CoverStyle(paletteIndex: index, motif: motif(for: entry.genre)),
            characters: [],
            isDemoContent: false,
            source: .personalShelf
        )
    }

    static let progress: [ReadingProgress] = zip(books, entries).map { book, entry in
        ReadingProgress(
            bookID: book.id,
            state: entry.state,
            currentChapter: 0,
            pagesRead: 0,
            startedAt: nil,
            finishedAt: entry.state == .finished ? DemoData.ago(days: 200) : nil,
            memoryStrength: entry.state == .finished ? 0.3 : 0
        )
    }
}
