// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Public-facing view of another reader's bookshelf.
/// Only shows books they've made public; no notes, highlights or private data.
struct UserPublicShelfView: View {
    let user: ExploreUser
    @Environment(AppRouter.self) private var router
    @State private var isFollowing: Bool

    init(user: ExploreUser) {
        self.user = user
        _isFollowing = State(initialValue: user.isFollowing)
    }

    private var books: [Book] {
        user.shelfBookIDs.compactMap { id in DemoData.books.first { $0.id == id } }
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    profileHeader
                    spineShelf
                    bookList
                    Text("Public shelf only — notes and private data are never shown.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
            }
        }
        .navigationTitle(user.firstName + "'s Shelf")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isFollowing ? "Following" : "Follow") {
                    isFollowing.toggle()
                }
                .font(.bbCaption)
                .foregroundStyle(isFollowing ? Theme.Palette.parchmentMuted : Theme.Palette.gold)
                .accessibilityLabel(isFollowing ? "Unfollow \(user.displayName)" : "Follow \(user.displayName)")
            }
        }
    }

    // MARK: Sub-views

    private var profileHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            MemberAvatar(name: user.displayName, seed: user.avatarSeed, size: 56)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(user.displayName)
                    .font(.bbTitle3)
                    .foregroundStyle(Theme.Palette.parchment)
                    .accessibilityAddTraits(.isHeader)
                Text(user.bio)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(user.favoriteGenres.prefix(3), id: \.self) { genre in
                        Text(genre.displayName)
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.lavender)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.Palette.inkHighlight))
                    }
                }
            }
        }
        .bbCard()
    }

    private var spineShelf: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Shelf")
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(.horizontal, Theme.Spacing.xs)
            BookShelfRow(books: books, emptyMessage: "No public books yet.") { book in
                router.push(.bookDetail(book.id))
            }
        }
    }

    private var bookList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("BOOKS")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .tracking(1.2)
                .padding(.horizontal, Theme.Spacing.xs)
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(books) { book in
                    Button {
                        router.push(.bookDetail(book.id))
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            BookCoverPlaceholder(book: book, size: .small, isDecorative: true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.bbHeadline)
                                    .foregroundStyle(Theme.Palette.parchment)
                                    .multilineTextAlignment(.leading)
                                Text(book.author)
                                    .font(.bbCaption)
                                    .foregroundStyle(Theme.Palette.parchmentMuted)
                                Text(book.genres.prefix(2).map(\.displayName).joined(separator: " · "))
                                    .font(.bbCaption)
                                    .foregroundStyle(Theme.Palette.lavender)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.Palette.parchmentMuted)
                                .accessibilityHidden(true)
                        }
                        .bbCard(padding: Theme.Spacing.md)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Opens book details")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserPublicShelfView(user: DemoData.exploreUsers[0])
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
