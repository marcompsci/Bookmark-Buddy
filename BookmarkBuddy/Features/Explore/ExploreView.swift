// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import Observation

// MARK: - ViewModel

@Observable
@MainActor
final class ExploreViewModel {
    private(set) var users: [ExploreUser] = DemoData.exploreUsers
    private(set) var recommendations: [BookRecommendation] = DemoData.communityRecommendations
    private var books: [Book] = DemoData.books
    private var followedIDs: Set<UUID> = []

    func shelfBooks(for user: ExploreUser) -> [Book] {
        user.shelfBookIDs.compactMap { id in books.first { $0.id == id } }
    }

    func recommendedBooks() -> [(recommendation: BookRecommendation, book: Book)] {
        recommendations.compactMap { rec in
            guard let book = books.first(where: { $0.id == rec.bookID }) else { return nil }
            return (rec, book)
        }
    }

    func toggleFollow(_ user: ExploreUser) {
        if followedIDs.contains(user.id) {
            followedIDs.remove(user.id)
        } else {
            followedIDs.insert(user.id)
        }
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx].isFollowing = followedIDs.contains(user.id)
        }
    }

    func addRecommendation(_ rec: BookRecommendation) {
        DemoData.communityRecommendations.insert(rec, at: 0)
        recommendations = DemoData.communityRecommendations
    }
}

// MARK: - ExploreView

struct ExploreView: View {
    @Environment(AppRouter.self) private var router
    @State private var model = ExploreViewModel()
    @State private var searchText = ""

    private var filteredUsers: [ExploreUser] {
        guard !searchText.isEmpty else { return model.users }
        return model.users.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.favoriteGenres.contains(where: { $0.displayName.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    exploreHeader
                    communityRecsCard
                    Text("READERS")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .tracking(1.5)
                        .padding(.horizontal, Theme.Spacing.xs)
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(filteredUsers) { user in
                            UserShelfCard(
                                user: user,
                                books: model.shelfBooks(for: user),
                                onFollowToggle: { model.toggleFollow(user) },
                                onViewShelf: { router.push(.userPublicShelf(user), in: .explore) },
                                onBookTap: { book in router.push(.bookDetail(book.id), in: .explore) }
                            )
                        }
                    }
                    Text("Showing demo community members — fictional data only.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .navigationTitle("Explore")
        .toolbar(.hidden, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search readers or genres")
    }

    // MARK: Sub-views

    private var exploreHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Explore")
                .font(.bbDisplay)
                .foregroundStyle(Theme.Palette.parchment)
                .accessibilityAddTraits(.isHeader)
            Text("Discover what other readers are enjoying.")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
        }
    }

    private var communityRecsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Label("Community Picks", systemImage: "sparkles")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.gold)
                Spacer()
                Button {
                    router.push(.recommendedShelf, in: .explore)
                } label: {
                    Text("See all")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                }
                .accessibilityLabel("See all community recommendations")
            }

            // Mini horizontal spine shelf of recommended books
            let pairs = model.recommendedBooks()
            if !pairs.isEmpty {
                BookShelfRow(
                    books: Array(pairs.prefix(6).map(\.book)),
                    emptyMessage: "No recommendations yet."
                ) { book in
                    router.push(.bookDetail(book.id), in: .explore)
                }
            }

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
            .accessibilityLabel("Recommend a book to the community shelf")
        }
        .bbCard()
    }
}

// MARK: - UserShelfCard

struct UserShelfCard: View {
    let user: ExploreUser
    let books: [Book]
    let onFollowToggle: () -> Void
    let onViewShelf: () -> Void
    let onBookTap: (Book) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header row
            HStack(spacing: Theme.Spacing.md) {
                MemberAvatar(name: user.displayName, seed: user.avatarSeed, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.parchment)
                    Text(user.favoriteGenres.prefix(2).map(\.displayName).joined(separator: " · "))
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                }
                Spacer()
                Button(action: onFollowToggle) {
                    Text(user.isFollowing ? "Following" : "Follow")
                        .font(.bbCaption)
                        .foregroundStyle(user.isFollowing ? Theme.Palette.parchmentMuted : Theme.Palette.ink)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(user.isFollowing ? Theme.Palette.inkHighlight : Theme.Palette.gold)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(user.isFollowing ? "Unfollow \(user.displayName)" : "Follow \(user.displayName)")
            }

            // Bio
            Text(user.bio)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)

            // Spine shelf preview
            BookShelfRow(books: books, emptyMessage: "No public books yet.") { book in
                onBookTap(book)
            }

            // View full shelf button
            Button(action: onViewShelf) {
                HStack {
                    Text("View \(user.firstName)'s full shelf")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.Palette.lavender)
                }
            }
            .buttonStyle(.plain)
        }
        .bbCard()
        .accessibilityElement(children: .contain)
    }
}

#Preview("Explore") {
    NavigationStack {
        ExploreView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
