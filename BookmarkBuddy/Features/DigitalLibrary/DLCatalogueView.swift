// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Every Digital Library book in one list, sortable by title, author or year.
struct DLCatalogueView: View {
    enum Sort: String, CaseIterable, Identifiable {
        case title = "Title", author = "Author", year = "Year"
        var id: String { rawValue }
    }

    @State private var sort: Sort = .title

    private var sorted: [DLBook] {
        switch sort {
        case .title: DLCatalog.books.sorted { $0.titleSortKey < $1.titleSortKey }
        case .author: DLCatalog.books.sorted { ($0.authorSortKey, $0.titleSortKey) < ($1.authorSortKey, $1.titleSortKey) }
        case .year: DLCatalog.books.sorted { ($0.year, $0.titleSortKey) < ($1.year, $1.titleSortKey) }
        }
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    DLEyebrow(text: "Every book, one list")
                    DLTypewriterText(text: "My Catalogue")
                    Text("\(DLCatalog.books.count) VOLUMES")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.Palette.gold)

                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(Sort.allCases) { option in
                            FilterChip(title: option.rawValue, isSelected: sort == option, style: .subtle) { sort = option }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Sort by")

                    LazyVStack(spacing: 0) {
                        ForEach(sorted) { book in
                            NavigationLink(value: AppRoute.digitalBook(id: book.id)) {
                                row(book)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    footer
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationTitle("My Catalogue")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ book: DLBook) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            LinearGradient(colors: [book.spine.backgroundColor, book.spine.accentColor], startPoint: .top, endPoint: .bottom)
                .frame(width: 6, height: 48)
                .clipShape(Capsule())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(.body, design: .serif).italic())
                    .foregroundStyle(Theme.Palette.parchment)
                Text(book.author)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                Text(book.genre.uppercased())
                    .font(.system(.caption2, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            Spacer()
            Text(verbatim: "\(book.year)")
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Theme.Palette.parchment)
        }
        .padding(.vertical, Theme.Spacing.md)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Palette.hairline).frame(height: 1) }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the book")
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(verbatim: "© \(Calendar.current.component(.year, from: .now)) Bookmark Buddy. All rights reserved.")
                .font(.bbCaption)
            Text("The app's design, code, descriptions, and cover and spine illustrations are original works owned by Omari. Book titles, author names, and quoted passages belong to their authors and publishers and appear here for commentary. Recommendations are visible to everyone who uses the app.")
                .font(.bbCaption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Theme.Palette.parchmentMuted)
        .padding(.top, Theme.Spacing.xl)
    }
}

#Preview {
    NavigationStack { DLCatalogueView() }
        .withPreviewEnvironment()
}
