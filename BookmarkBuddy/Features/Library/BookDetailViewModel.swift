// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class BookDetailViewModel {
    struct Content {
        var book: Book
        var progress: ReadingProgress?
        var notes: [BookNote]
        var moments: [SavedMoment]
        var hasQuiz: Bool

        var state: ReadingState { progress?.state ?? .wantToRead }
    }

    static let noteLimit = 500

    let bookID: UUID
    private(set) var state: LoadState<Content> = .idle
    var summaryMode: SummaryMode = .premise
    private(set) var summary: LoadState<SummaryResult> = .idle
    var draftNote = ""
    private(set) var isSaving = false

    init(bookID: UUID) {
        self.bookID = bookID
    }

    var content: Content? { state.value }

    func load(services: AppServices) async {
        if content == nil { state = .loading }
        do {
            async let book = services.books.book(id: bookID)
            async let progress = services.books.progress(for: bookID)
            async let notes = services.books.notes(for: bookID)
            async let moments = services.books.moments(for: bookID)
            async let modes = services.quizzes.availableModes(for: bookID)
            let loadedBook = try await book
            let loadedProgress = try await progress
            let loadedNotes = try await notes
            let loadedMoments = try await moments
            let loadedModes = await modes
            state = .loaded(Content(
                book: loadedBook,
                progress: loadedProgress,
                notes: loadedNotes,
                moments: loadedMoments,
                hasQuiz: !loadedModes.isEmpty
            ))
        } catch {
            if content == nil { state = .failed(error.localizedDescription) }
        }
    }

    // MARK: Summary

    func loadSummary(services: AppServices, spoilerLevel: SpoilerLevel) async {
        guard let content else { return }
        summary = .loading
        do {
            let result = try await services.summaries.summary(
                for: content.book,
                mode: summaryMode,
                progress: content.progress,
                spoilerLevel: spoilerLevel
            )
            summary = .loaded(result)
        } catch {
            summary = .failed("The summary couldn't load. Try again.")
        }
    }

    // MARK: Progress

    /// Logging a chapter only changes the reader's own progress, so it doesn't need confirmation.
    func logChapter(services: AppServices) async {
        guard var current = content, var progress = current.progress, current.book.hasChapterData else { return }
        progress.currentChapter = min(current.book.chapterCount, progress.currentChapter + 1)
        let pagesPerChapter = current.book.pageCount / max(1, current.book.chapterCount)
        progress.pagesRead = min(current.book.pageCount, progress.pagesRead + pagesPerChapter)
        if progress.currentChapter >= current.book.chapterCount {
            progress.state = .finished
            progress.finishedAt = .now
            progress.pagesRead = current.book.pageCount
        }
        await save(progress, into: &current, services: services)
    }

    func startReading(services: AppServices) async {
        guard var current = content else { return }
        var progress = current.progress ?? ReadingProgress(
            bookID: current.book.id, state: .wantToRead, currentChapter: 0,
            pagesRead: 0, startedAt: nil, finishedAt: nil, memoryStrength: 0
        )
        progress.state = .reading
        progress.startedAt = .now
        progress.currentChapter = current.book.hasChapterData ? max(1, progress.currentChapter) : 0
        await save(progress, into: &current, services: services)
    }

    private func save(_ progress: ReadingProgress, into current: inout Content, services: AppServices) async {
        do {
            try await services.books.updateProgress(progress)
            current.progress = progress
            state = .loaded(current)
        } catch {
            // Keep the previous state; the UI stays unchanged.
        }
    }

    // MARK: Notes & moments

    var canAddNote: Bool {
        !draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    func enforceNoteLimit() {
        if draftNote.count > Self.noteLimit {
            draftNote = String(draftNote.prefix(Self.noteLimit))
        }
    }

    /// Notes are private to this device, so adding one doesn't need confirmation. Deleting does.
    func addNote(services: AppServices) async {
        guard canAddNote, var current = content else { return }
        isSaving = true
        defer { isSaving = false }
        let note = BookNote(
            bookID: current.book.id,
            chapter: current.progress?.currentChapter ?? 0,
            text: draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        do {
            try await services.books.addNote(note)
            current.notes.insert(note, at: 0)
            state = .loaded(current)
            draftNote = ""
        } catch {}
    }

    func addMoment(title: String, reflection: String, services: AppServices) async -> Bool {
        guard var current = content else { return false }
        let moment = SavedMoment(
            bookID: current.book.id,
            chapter: current.progress?.currentChapter ?? 0,
            title: title,
            reflection: reflection
        )
        do {
            try await services.books.addMoment(moment)
            current.moments.insert(moment, at: 0)
            state = .loaded(current)
            return true
        } catch {
            return false
        }
    }
}
