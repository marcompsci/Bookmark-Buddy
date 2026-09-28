// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Community-recommended book shelf. Shows books spine-style at the top, then
/// individual recommendation cards below with who recommended each and their note.
struct RecommendedShelfView: View {
    @Environment(AppRouter.self) private var router

    private var pairs: [(rec: BookRecommendation, book: Book)] {
        DemoData.communityRecommendations.compactMap { rec in
            guard let book = DemoData.books.first(where: { $0.id == rec.bookID }) else { return nil }
            return (rec, book)
        }
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header

                    if pairs.isEmpty {
                        EmptyStateView(
                            systemImage: "books.vertical",
                            title: "No recommendations yet",
                            message: "Be the first \u{2014} tap Recommend a book to add one.",
                            actionTitle: "Recommend a book"
                        ) {
                            router.present(.recommendBook)
                        }
                        .bbCard()
                    } else {
                        // Spine shelf visual
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("The shelf")
                                .font(.bbHeadline)
                                .foregroundStyle(Theme.Palette.parchment)
                                .padding(.horizontal, Theme.Spacing.xs)
                            BookShelfRow(books: pairs.map(\.book)) { book in
                                router.push(.bookDetail(book.id))
                            }
                        }

                        // Recommend button
                        Button {
                            router.present(.recommendBook)
                        } label: {
                            Label("Recommend a book", systemImage: "plus.circle.fill")
                                .font(.bbHeadline)
                                .foregroundStyle(Theme.Palette.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Capsule().fill(Theme.Palette.gold))
                        }
                        .buttonStyle(.plain)

                        // Individual recommendation cards
                        Text("ALL RECOMMENDATIONS")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .tracking(1.2)
                            .padding(.horizontal, Theme.Spacing.xs)

                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(pairs, id: \.rec.id) { pair in
                                RecommendationRow(rec: pair.rec, book: pair.book) {
                                    router.push(.bookDetail(pair.book.id))
                                }
                            }
                        }
                    }

                    Text("Demo content — community recommendations are local only in this MVP.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .navigationTitle("Community Picks")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Label("Community Picks", systemImage: "sparkles")
                .font(.bbTitle)
                .foregroundStyle(Theme.Palette.gold)
                .accessibilityAddTraits(.isHeader)
            Text("Books readers in the community are recommending right now.")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Row

private struct RecommendationRow: View {
    let rec: BookRecommendation
    let book: Book
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                BookCoverPlaceholder(book: book, size: .small, isDecorative: true)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(book.title)
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.parchment)
                        .multilineTextAlignment(.leading)
                    Text(book.author)
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                    if let note = rec.note, !note.isEmpty {
                        Text("\u{201C}\(note)\u{201D}")
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchment.opacity(0.85))
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.lavender)
                        Text("Recommended by \(rec.recommenderName)")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.lavender)
                        Text("·")
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                        Text(rec.createdAt.formatted(.relative(presentation: .named)))
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .bbCard(padding: Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens book details")
    }
}

#Preview {
    NavigationStack {
        RecommendedShelfView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
