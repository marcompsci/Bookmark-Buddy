// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Builds "Demo AI summaries" from chapter-tagged story beats and enforces spoiler rules.
///
/// Rules:
/// - Premise: setup beats only. Never includes development or resolution.
/// - Where I am: beats up to the reader's current chapter, never resolution beats,
///   and only if the reader's spoiler level is at least "Current chapter".
/// - Full recap: every beat, only if the book is finished and the spoiler level is at least
///   "Finished book" — or the reader chose "Full spoilers".
///
/// TODO(prod): Replace with an AI provider call that receives only licensed, source-linked
/// material, and re-check spoiler limits server-side before returning text.
actor MockSummaryService: SummaryService {
    private let latency: Duration

    init(latency: Duration = .milliseconds(600)) {
        self.latency = latency
    }

    func summary(for book: Book, mode: SummaryMode, progress: ReadingProgress?, spoilerLevel: SpoilerLevel) async throws -> SummaryResult {
        await DemoLatency.pause(latency)
        let beats = DemoData.beats[book.id] ?? []
        let state = progress?.state ?? .wantToRead
        let chapter = progress?.currentChapter ?? 0

        // Real books from the personal shelf have no licensed plot data, so the demo never
        // writes summaries of them. Only their metadata-based premise line is shown.
        if beats.isEmpty && mode != .premise {
            return .locked(reason: "Summaries for this title need licensed, source-linked content, which the demo doesn't include yet.")
        }

        switch mode {
        case .premise:
            let setup = beats.filter { $0.kind == .setup }.map(\.text)
            let text = setup.isEmpty ? book.premise : setup.joined(separator: " ")
            return .available(BookSummary(bookID: book.id, mode: .premise, text: text, coveredThroughChapter: nil))

        case .whereIAm:
            guard spoilerLevel >= .currentChapter else {
                return .locked(reason: "Your spoiler setting is “Premise only.” Change it in Profile to see chapter summaries.")
            }
            guard state != .wantToRead, chapter > 0 else {
                return .locked(reason: "Start reading to unlock a summary of where you are.")
            }
            let visible = beats.filter { $0.chapter <= chapter && $0.kind != .resolution }
            guard !visible.isEmpty else {
                return .locked(reason: "Nothing to recap yet — keep reading!")
            }
            let text = visible.map { "Ch. \($0.chapter): \($0.text)" }.joined(separator: "\n")
            return .available(BookSummary(bookID: book.id, mode: .whereIAm, text: text, coveredThroughChapter: chapter))

        case .fullRecap:
            let allowed = spoilerLevel == .fullSpoilers || (spoilerLevel >= .finishedBook && state == .finished)
            guard allowed else {
                if state != .finished {
                    return .locked(reason: "Full recaps unlock when you finish the book. Your spoiler setting keeps endings hidden until then.")
                }
                return .locked(reason: "Your spoiler setting hides full recaps. Change it in Profile if you'd like to see them.")
            }
            let text = beats.map { "Ch. \($0.chapter): \($0.text)" }.joined(separator: "\n")
            return .available(BookSummary(bookID: book.id, mode: .fullRecap, text: text, coveredThroughChapter: book.chapterCount))
        }
    }
}
