// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Client-side spoiler rules shared by the Library, quizzes and Pip.
/// TODO(prod): Mirror these checks server-side; never trust the client alone.
enum SpoilerPolicy {
    /// The furthest chapter the reader may see content from.
    static func visibleThroughChapter(book: Book, progress: ReadingProgress?, level: SpoilerLevel) -> Int {
        if level == .fullSpoilers { return book.chapterCount }
        guard let progress else { return 0 }
        switch level {
        case .premiseOnly:
            return 0
        case .currentChapter:
            return progress.state == .finished ? book.chapterCount : progress.currentChapter
        case .finishedBook:
            return progress.state == .finished ? book.chapterCount : progress.currentChapter
        case .fullSpoilers:
            return book.chapterCount
        }
    }

    /// Quiz questions the reader can see without spoilers. Once a book is finished, nothing in it
    /// is a spoiler any more; before that, questions stop at the reader's current chapter.
    /// Metadata-only questions (chapter 0) are always allowed.
    static func allowedQuestions(_ questions: [QuizQuestion], book: Book?, progress: ReadingProgress?, level: SpoilerLevel) -> [QuizQuestion] {
        guard book != nil else { return questions.filter { $0.drawsOnChapter == 0 } }
        if progress?.state == .finished || level == .fullSpoilers { return questions }
        let limit = level == .premiseOnly ? 0 : (progress?.currentChapter ?? 0)
        return questions.filter { $0.drawsOnChapter <= limit }
    }

    /// Characters the reader has already met. Premise-level readers see only chapter-1 characters.
    static func visibleCharacters(book: Book, progress: ReadingProgress?, level: SpoilerLevel) -> (visible: [BookCharacter], hiddenCount: Int) {
        let limit = max(1, visibleThroughChapter(book: book, progress: progress, level: level))
        let visible = book.characters
            .filter { $0.introducedInChapter <= limit }
            .sorted { $0.introducedInChapter < $1.introducedInChapter }
        return (visible, book.characters.count - visible.count)
    }
}
