// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// PERSONAL SHELF
// Real books from the owner's reading history. Metadata (title, author, page
// count, chapter count, genre, brief factual description) is drawn from
// publicly available bibliographic sources. No proprietary text is reproduced.
//
// TODO(prod): Replace with the user's synced library + a licensed catalog API
// (Open Library / Google Books) for ISBNs, cover art, and publisher-approved
// descriptions. Progress starts at 0 so the user owns their own reading state.
// ─────────────────────────────────────────────────────────────────────────────

enum PersonalShelf {
    private struct Entry {
        let title: String
        let author: String
        let genre: Genre
        let pageCount: Int
        let chapterCount: Int
        let premise: String
        var state: ReadingState = PersonalShelf.defaultState
    }

    static let defaultState: ReadingState = .finished

    private static let entries: [Entry] = [
        Entry(
            title: "The Intelligent Investor",
            author: "Benjamin Graham",
            genre: .finance,
            pageCount: 623,
            chapterCount: 20,
            premise: "Benjamin Graham's definitive guide to value investing, built on the principle that an intelligent investor buys stakes in real businesses rather than speculating on price movements. The foundational text for long-term wealth building, centered on his concept of the margin of safety."
        ),
        Entry(
            title: "Money Works: The Guide to Financial Literacy",
            author: "Abhijeet Kolapkar",
            genre: .finance,
            pageCount: 196,
            chapterCount: 8,
            premise: "A practical, first-principles guide to understanding money — how to earn, budget, invest, and avoid the traps that keep most people financially stuck. Kolapkar makes personal finance concrete enough to act on from the first page."
        ),
        Entry(
            title: "The Let Them Theory",
            author: "Mel Robbins",
            genre: .selfGrowth,
            pageCount: 320,
            chapterCount: 12,
            premise: "Mel Robbins argues that the fastest path to personal peace is letting go of the need to control what others think, say, or do. A simple two-word mindset shift — 'let them' — that stops the spiral of resentment and reclaims your energy for what matters."
        ),
        Entry(
            title: "Open",
            author: "Andre Agassi",
            genre: .memoir,
            pageCount: 385,
            chapterCount: 40,
            premise: "Andre Agassi's unflinching memoir about a tennis career he spent much of hating — and the unlikely path to finding his own identity after winning eight Grand Slam titles. One of the most honest sports autobiographies ever written."
        ),
        Entry(
            title: "The Shining",
            author: "Stephen King",
            genre: .horror,
            pageCount: 447,
            chapterCount: 58,
            premise: "Jack Torrance moves his family to the isolated Overlook Hotel as its winter caretaker, hoping the solitude will help him write. The hotel has other plans — and his young son Danny may be what it wants most. Stephen King's most psychologically precise novel."
        ),
        Entry(
            title: "It",
            author: "Stephen King",
            genre: .horror,
            pageCount: 1138,
            chapterCount: 23,
            premise: "In Derry, Maine, seven outcast kids face a shapeshifting evil that preys on children — and are pulled back as adults when the killings start again. A novel about the way childhood terror and deep friendship are the two things people carry longest into their lives."
        ),
        Entry(
            title: "David and Goliath",
            author: "Malcolm Gladwell",
            genre: .ideas,
            pageCount: 305,
            chapterCount: 9,
            premise: "Gladwell reframes underdogs, misfits, and the art of battling giants by showing that what looks like a disadvantage often conceals unexpected strengths. A systematic challenge to every assumption about who wins and why."
        ),
        Entry(
            title: "The Tipping Point",
            author: "Malcolm Gladwell",
            genre: .ideas,
            pageCount: 301,
            chapterCount: 9,
            premise: "Gladwell introduces the idea that social epidemics tip into mass adoption through a precise combination of the right people, the right message, and the right context. The book that made 'tipping point' part of everyday language."
        ),
        Entry(
            title: "Outliers",
            author: "Malcolm Gladwell",
            genre: .ideas,
            pageCount: 309,
            chapterCount: 10,
            premise: "Gladwell argues that exceptional achievement is less about raw talent than about timing, culture, and the accumulation of practice — most famously, the 10,000-hour rule. A systematic dismantling of the myth that success is purely self-made."
        ),
        Entry(
            title: "Atomic Habits",
            author: "James Clear",
            genre: .selfGrowth,
            pageCount: 320,
            chapterCount: 20,
            premise: "James Clear argues that meaningful change comes from systems of tiny behaviors that compound over time, not from motivation. A rigorous, practical guide to the four laws of behavior change — and why identity, not outcomes, is where lasting habits begin."
        ),
        Entry(
            title: "Don't Believe Everything You Think",
            author: "Joseph Nguyen",
            genre: .mindfulness,
            pageCount: 115,
            chapterCount: 12,
            premise: "Nguyen argues that human suffering comes not from circumstances but from the act of believing negative thoughts as if they were facts. A short, direct case for stepping back from automatic thinking and letting thoughts pass without attachment."
        ),
        Entry(
            title: "Ikigai",
            author: "Francesc Miralles",
            genre: .mindfulness,
            pageCount: 208,
            chapterCount: 10,
            premise: "Drawing on the lives of Okinawa's centenarians, Miralles and García explore the Japanese concept of ikigai — your reason for getting up in the morning. Staying purposefully engaged with life, they argue, may matter more than diet or exercise."
        ),
        Entry(
            title: "The Alchemist",
            author: "Paulo Coelho",
            genre: .fiction,
            pageCount: 208,
            chapterCount: 18,
            premise: "Santiago, an Andalusian shepherd boy, journeys across North Africa in pursuit of a treasure he dreamed about — and discovers that learning to read the signs the universe places in your path is the real journey. Coelho's most-read novel, translated into more than 80 languages."
        ),
        Entry(
            title: "The Mountain Is You",
            author: "Brianna Wiest",
            genre: .selfGrowth,
            pageCount: 264,
            chapterCount: 10,
            premise: "Wiest reframes self-sabotage as a form of self-protection that has outlived its usefulness, and guides readers toward understanding why they stand in their own way. The mountain blocking your path is not the obstacle — it is the path itself."
        ),
        Entry(
            title: "The Art of Letting Go",
            author: "Lucas Hayes",
            genre: .selfGrowth,
            pageCount: 192,
            chapterCount: 8,
            premise: "A practical guide to releasing attachment to outcomes, relationships, and identities that no longer serve you — with concrete exercises for recognizing when holding on costs more than letting go. Direct and action-oriented throughout."
        ),
        Entry(
            title: "Dare to Succeed",
            author: "Success Center",
            genre: .selfGrowth,
            pageCount: 192,
            chapterCount: 6,
            premise: "A motivational framework for setting goals and executing on ambitions without waiting for perfect conditions. Compact chapters designed to be read and acted on immediately rather than absorbed and shelved."
        ),
        Entry(
            title: "The Body Keeps the Score",
            author: "Bessel van der Kolk",
            genre: .health,
            pageCount: 464,
            chapterCount: 17,
            premise: "Van der Kolk synthesizes decades of trauma research to show how unprocessed trauma reshapes the brain and body — and surveys the therapies, from EMDR to theater to yoga, that help people actually heal. The most widely read book on trauma published in the last thirty years."
        )
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
            pageCount: entry.pageCount,
            chapterCount: entry.chapterCount,
            premise: entry.premise,
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
            currentChapter: entry.state == .finished ? entry.chapterCount : 0,
            pagesRead: entry.state == .finished ? entry.pageCount : 0,
            startedAt: nil,
            finishedAt: entry.state == .finished ? DemoData.ago(days: 200) : nil,
            memoryStrength: entry.state == .finished ? 0.3 : 0
        )
    }
}
