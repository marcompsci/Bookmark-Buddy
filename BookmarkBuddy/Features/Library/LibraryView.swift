// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct LibraryView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @State private var model = LibraryViewModel()

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    DigitalLibraryBanner()
                    segmentPicker
                    if model.segment != .moments, !model.availableGenres.isEmpty {
                        genreChips
                    }
                    content
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .refreshable { await model.load(services: services) }
        }
        .navigationTitle("Library")
        .searchable(text: $model.searchText, prompt: "Title, author or genre")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sourceMenu
            }
        }
        .task(id: router.dataVersion) {
            await model.load(services: services)
        }
    }

    // MARK: Segments

    private var segmentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(LibrarySegment.allCases) { segment in
                    FilterChip(
                        title: segment.title,
                        count: model.content == nil ? nil : model.count(for: segment),
                        isSelected: model.segment == segment
                    ) {
                        model.select(segment)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Library shelves")
    }

    private var genreChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                FilterChip(title: "All genres", isSelected: model.genreFilter == nil, style: .subtle) {
                    model.genreFilter = nil
                }
                ForEach(model.availableGenres) { genre in
                    FilterChip(title: genre.displayName, systemImage: genre.symbol, isSelected: model.genreFilter == genre, style: .subtle) {
                        model.genreFilter = model.genreFilter == genre ? nil : genre
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Genre filters")
    }

    private var sourceMenu: some View {
        Menu {
            Picker("Show", selection: $model.sourceFilter) {
                ForEach(LibrarySourceFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
        } label: {
            Image(systemName: model.sourceFilter == .all
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
                .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
        }
        .accessibilityLabel("Filter books by source")
        .accessibilityValue(model.sourceFilter.title)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            VStack(spacing: Theme.Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in LoadingCard(label: "Loading your library", lines: 3) }
            }
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await model.load(services: services) }
            }
        case .loaded:
            if model.segment == .moments {
                momentsList
            } else {
                // Spine shelf sits above the list for a physical library feel.
                if !model.filteredBooks.isEmpty {
                    librarySpineShelf
                }
                booksList
            }
        }
    }

    private var librarySpineShelf: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(model.segment.title)
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(.horizontal, Theme.Spacing.xs)

            BookShelfRow(
                books: model.filteredBooks.map(\.book),
                emptyMessage: "Nothing on this shelf."
            ) { book in
                router.push(.bookDetail(book.id))
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var booksList: some View {
        let books = model.filteredBooks
        if books.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(books) { item in
                    NavigationLink(value: AppRoute.bookDetail(item.book.id)) {
                        LibraryBookRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var momentsList: some View {
        let moments = model.filteredMoments
        if moments.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(moments, id: \.moment.id) { entry in
                    NavigationLink(value: AppRoute.bookDetail(entry.book.id)) {
                        SavedMomentRow(moment: entry.moment, bookTitle: entry.book.title)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if model.hasActiveFilters {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No matches",
                message: "Nothing on this shelf matches your search or filters.",
                actionTitle: "Clear filters"
            ) {
                model.clearFilters()
            }
        } else {
            switch model.segment {
            case .reading:
                EmptyStateView(systemImage: "book", title: "Nothing in progress", message: "Start a book from Want to Read and it will show up here.")
            case .wantToRead:
                EmptyStateView(systemImage: "bookmark", title: "Your list is empty", message: "Books you want to read next will appear here.")
            case .finished:
                EmptyStateView(systemImage: "checkmark.seal", title: "No finished books yet", message: "Finish a book to grow your Memory Garden.")
            case .moments:
                EmptyStateView(systemImage: "sparkles", title: "No saved moments", message: "Open any book and tap “Save a moment” to keep a thought in your own words.")
            }
        }
    }
}

// MARK: - Rows & chips

struct FilterChip: View {
    enum Style { case prominent, subtle }

    let title: String
    var systemImage: String?
    var count: Int?
    let isSelected: Bool
    var style: Style = .prominent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
                if let count {
                    Text("\(count)")
                        .font(.bbCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(isSelected ? Theme.Palette.ink.opacity(0.15) : Theme.Palette.inkHighlight))
                }
            }
            .font(style == .prominent ? .bbHeadline : .bbCallout)
            .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.parchment)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(minHeight: Theme.minTapTarget)
            .background(
                Capsule().fill(isSelected ? (style == .prominent ? Theme.Palette.gold : Theme.Palette.lavender) : Theme.Palette.inkRaised)
            )
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Theme.Palette.hairline, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(title), \($0)" } ?? title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct LibraryBookRow: View {
    let item: BookWithProgress

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            BookCoverPlaceholder(book: item.book, size: .small, isDecorative: true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(item.book.title)
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.book.author)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                Text(item.book.genres.map(\.displayName).joined(separator: " · "))
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
                statusLine
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .accessibilityHidden(true)
        }
        .bbCard(padding: Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens book details")
    }

    @ViewBuilder
    private var statusLine: some View {
        switch item.state {
        case .reading:
            VStack(alignment: .leading, spacing: 4) {
                ReadingProgressBar(fraction: item.fraction, height: 6, label: "Progress")
                if let progress = item.progress, item.book.hasChapterData {
                    Text("Chapter \(progress.currentChapter) of \(item.book.chapterCount)")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
            }
            .padding(.top, 2)
        case .finished:
            Label(item.book.source == .personalShelf ? "On your shelf" : "Finished", systemImage: "checkmark.seal.fill")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.forestBright)
        case .wantToRead:
            Label("Want to read", systemImage: "bookmark")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
        }
    }
}

struct SavedMomentRow: View {
    let moment: SavedMoment
    let bookTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Palette.gold)
                    .accessibilityHidden(true)
                Text(moment.title)
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                Spacer(minLength: 0)
                if moment.chapter > 0 {
                    Text("Ch. \(moment.chapter)")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
            }
            Text(moment.reflection)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchment)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if let bookTitle {
                Text(bookTitle)
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
            }
        }
        .bbCard(padding: Theme.Spacing.md)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Library") {
    NavigationStack {
        LibraryView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}

// MARK: - Digital Library entry

/// Entry point to Omari's Digital Library: a strip of real spines and a link to the shelf.
private struct DigitalLibraryBanner: View {
    var body: some View {
        NavigationLink(value: AppRoute.digitalShelf(genre: nil)) {
            HStack(alignment: .bottom, spacing: Theme.Spacing.md) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(DLCatalog.books.prefix(6)) { book in
                        DLSpineView(book: book, scale: 0.26)
                    }
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    DLEyebrow(text: "A personal archive")
                    Text("Omari's Digital Library")
                        .font(.system(.title3, design: .serif).italic())
                        .foregroundStyle(Theme.Palette.parchment)
                    Text("\(DLCatalog.books.count) volumes · quotes, summaries, recommendations")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
            }
            .bbCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Omari's Digital Library, \(DLCatalog.books.count) volumes")
        .accessibilityHint("Opens the shelf")
    }
}
