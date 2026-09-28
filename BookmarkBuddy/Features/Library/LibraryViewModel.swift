// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

enum LibrarySegment: String, CaseIterable, Identifiable, Hashable {
    case reading, wantToRead, finished, moments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading: "Reading"
        case .wantToRead: "Want to Read"
        case .finished: "Finished"
        case .moments: "Saved Moments"
        }
    }

    var readingState: ReadingState? {
        switch self {
        case .reading: .reading
        case .wantToRead: .wantToRead
        case .finished: .finished
        case .moments: nil
        }
    }
}

enum LibrarySourceFilter: String, CaseIterable, Identifiable, Hashable {
    case all, shelf, demo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All books"
        case .shelf: "My shelf"
        case .demo: "Demo titles"
        }
    }

    func includes(_ book: Book) -> Bool {
        switch self {
        case .all: true
        case .shelf: book.source == .personalShelf
        case .demo: book.source == .demo
        }
    }
}

@Observable
@MainActor
final class LibraryViewModel {
    struct Content {
        var books: [BookWithProgress]
        var moments: [SavedMoment]
    }

    private(set) var state: LoadState<Content> = .idle
    var segment: LibrarySegment = .reading
    var searchText = ""
    var genreFilter: Genre?
    var sourceFilter: LibrarySourceFilter = .all

    var content: Content? { state.value }

    func load(services: AppServices) async {
        if content == nil { state = .loading }
        do {
            async let books = services.books.library()
            async let moments = services.books.allMoments()
            let loadedBooks = try await books
            let loadedMoments = try await moments
            state = .loaded(Content(books: loadedBooks, moments: loadedMoments))
        } catch {
            if content == nil { state = .failed(error.localizedDescription) }
        }
    }

    // MARK: Derived

    private var normalizedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Matches title, author or genre — the same fields the Digital Library site searches.
    private func matchesSearch(_ book: Book) -> Bool {
        let query = normalizedQuery
        guard !query.isEmpty else { return true }
        return book.title.localizedCaseInsensitiveContains(query)
            || book.author.localizedCaseInsensitiveContains(query)
            || book.genres.contains { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    private func booksInSegment(_ segment: LibrarySegment) -> [BookWithProgress] {
        guard let state = segment.readingState else { return [] }
        return (content?.books ?? []).filter { $0.state == state && sourceFilter.includes($0.book) }
    }

    func count(for segment: LibrarySegment) -> Int {
        segment == .moments ? (content?.moments.count ?? 0) : booksInSegment(segment).count
    }

    /// Genres present in the current segment, for the filter chips.
    var availableGenres: [Genre] {
        let present = Set(booksInSegment(segment).flatMap(\.book.genres))
        return Genre.allCases.filter { present.contains($0) }
    }

    var filteredBooks: [BookWithProgress] {
        booksInSegment(segment)
            .filter { matchesSearch($0.book) }
            .filter { item in genreFilter.map { item.book.genres.contains($0) } ?? true }
            .sorted { $0.book.title.localizedCaseInsensitiveCompare($1.book.title) == .orderedAscending }
    }

    var filteredMoments: [(moment: SavedMoment, book: Book)] {
        guard let content else { return [] }
        let booksByID = Dictionary(content.books.map { ($0.book.id, $0.book) }, uniquingKeysWith: { first, _ in first })
        let query = normalizedQuery
        return content.moments.compactMap { moment -> (moment: SavedMoment, book: Book)? in
            guard let book = booksByID[moment.bookID] else { return nil }
            if !query.isEmpty,
               !moment.title.localizedCaseInsensitiveContains(query),
               !moment.reflection.localizedCaseInsensitiveContains(query),
               !matchesSearch(book) {
                return nil
            }
            return (moment: moment, book: book)
        }
    }

    var hasActiveFilters: Bool {
        !normalizedQuery.isEmpty || genreFilter != nil || sourceFilter != .all
    }

    func clearFilters() {
        searchText = ""
        genreFilter = nil
        sourceFilter = .all
    }

    func select(_ segment: LibrarySegment) {
        self.segment = segment
        // A genre chosen on one shelf may not exist on another.
        if let genreFilter, !availableGenres.contains(genreFilter) {
            self.genreFilter = nil
        }
    }
}
