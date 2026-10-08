// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Omari's Digital Library: typewriter header, search and genre chips, the spine shelf
/// (books stand up one by one like dominoes), and the floating recommendations shelf.
struct DLShelfView: View {
    var initialGenre: String?

    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var genre: String?
    @State private var query = ""
    @State private var recommendations: [DLRecommendation] = []
    @State private var didSetInitialGenre = false

    private var visibleBooks: [DLBook] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return DLCatalog.books.filter { book in
            let genreOK = genre == nil || book.genre == genre
            let queryOK = q.isEmpty || "\(book.title) \(book.subtitle ?? "") \(book.author) \(book.genre)".lowercased().contains(q)
            return genreOK && queryOK
        }
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header
                    DLRecommendationShelf(recommendations: recommendations) {
                        router.push(.recommendToOmari)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        DLEyebrow(text: "The shelf")
                        genreChips
                        DLSpineShelf(books: visibleBooks, animationKey: "\(genre ?? "all")|\(query)")
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Digital Library")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "What are you looking for?")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { menu }
        }
        .onAppear {
            if !didSetInitialGenre {
                genre = initialGenre
                didSetInitialGenre = true
            }
        }
        .task(id: router.dataVersion) {
            recommendations = (try? await services.shelfRecommendations.all()) ?? []
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            DLEyebrow(text: "A personal archive")
            DLTypewriterText(text: "Omari's Digital Library")
            Text("\(DLCatalog.books.count) VOLUMES")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .tracking(2)
                .foregroundStyle(Theme.Palette.gold)
            Text("What I've read, what shaped how I think about money, habits, and the stories worth staying up for.")
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.sm) { headerButtons }
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) { headerButtons }
            }
        }
    }

    @ViewBuilder
    private var headerButtons: some View {
        DLPillButton(title: "My Catalogue") { router.push(.digitalCatalogue) }
        DLPillButton(title: "Recommend a book", filled: false) { router.push(.recommendToOmari) }
    }

    private var genreChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                FilterChip(title: "All", isSelected: genre == nil, style: .subtle) { genre = nil }
                ForEach(DLCatalog.genres, id: \.self) { name in
                    FilterChip(title: name, count: DLCatalog.count(in: name), isSelected: genre == name, style: .subtle) {
                        genre = genre == name ? nil : name
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Genres")
    }

    /// Replaces the website's hamburger: genres with counts, then Browse links.
    private var menu: some View {
        Menu {
            Section("Genres") {
                ForEach(DLCatalog.genres, id: \.self) { name in
                    Button {
                        genre = name
                    } label: {
                        Text(verbatim: "\(name)  \(String(format: "%02d", DLCatalog.count(in: name)))")
                    }
                }
            }
            Section("Browse") {
                Button("The shelf") { genre = nil; query = "" }
                Button("My catalogue") { router.push(.digitalCatalogue) }
                Button("Recommend a book") { router.push(.recommendToOmari) }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
        }
        .accessibilityLabel("Library menu")
    }
}

// MARK: - Spine shelf

/// Spines standing on a ledge. When the set of books changes, they stand up left to right
/// like dominoes (rotated 88° around their bottom-left corner, then swinging upright).
struct DLSpineShelf: View {
    let books: [DLBook]
    let animationKey: String

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var standing: Set<String> = []
    @State private var ledgeProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if books.isEmpty {
                Text("Nothing on the shelf matches that.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(books) { book in
                                NavigationLink(value: AppRoute.digitalBook(id: book.id)) {
                                    DLSpineView(book: book)
                                        .rotationEffect(.degrees(standing.contains(book.id) ? 0 : 88), anchor: .bottomLeading)
                                        .opacity(standing.contains(book.id) ? 1 : 0)
                                }
                                .buttonStyle(DLSpinePressStyle())
                                .contextMenu {
                                    Button {
                                        router.push(.digitalBook(id: book.id))
                                    } label: {
                                        Label("Open", systemImage: "book")
                                    }
                                } preview: {
                                    DLSpineInfoCard(book: book)
                                }
                                .accessibilityHint("Opens the book")
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.top, Theme.Spacing.lg)

                        // Ledge grows in left to right after the last book lands.
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(colors: [Color(hex: "#5A4632"), Color(hex: "#3B2D20")], startPoint: .top, endPoint: .bottom))
                                .frame(width: geo.size.width * ledgeProgress, height: 10)
                                .shadow(color: .black.opacity(0.5), radius: 6, y: 5)
                        }
                        .frame(height: 14)
                    }
                }
            }
        }
        .task(id: animationKey) { await standUp() }
    }

    private func standUp() async {
        let ids = books.map(\.id)
        if reduceMotion {
            standing = Set(ids)
            ledgeProgress = 1
            return
        }
        standing = []
        ledgeProgress = 0
        for id in ids {
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                _ = standing.insert(id)
            }
            try? await Task.sleep(for: .milliseconds(70))
        }
        withAnimation(.easeOut(duration: 0.5)) { ledgeProgress = 1 }
    }
}

/// Lifts a spine slightly while pressed.
private struct DLSpinePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -8 : 0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// The small card shown when you press and hold a spine.
struct DLSpineInfoCard: View {
    let book: DLBook

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(book.title)
                .font(.system(.title3, design: .serif).italic())
            Text(book.author)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(verbatim: "\(book.year) · \(book.publisher)")
                .font(.caption.monospaced())
            Text(book.genre.uppercased())
                .font(.caption2.monospaced())
                .tracking(1.5)
                .foregroundStyle(Color(hex: book.spine.accent))
        }
        .padding()
        .frame(width: 260, alignment: .leading)
    }
}

// MARK: - Floating recommendations shelf

/// A plank that gently bobs, with recommended books lying flat on it (newest on top, max 8).
struct DLRecommendationShelf: View {
    let recommendations: [DLRecommendation]
    let onAdd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            DLEyebrow(text: "Recommended to me")
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 0) {
                VStack(spacing: 1) {
                    if recommendations.count > 8 {
                        Text("+ \(recommendations.count - 8) more")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .padding(.bottom, 4)
                    }
                    // Newest on top.
                    ForEach(Array(recommendations.prefix(8).enumerated()), id: \.element.id) { index, rec in
                        DLFlatBookView(recommendation: rec, width: 160 + CGFloat((rec.title.count * 7) % 40))
                            .offset(x: CGFloat((index * 13) % 18) - 9)
                    }
                    if recommendations.isEmpty {
                        Text("No recommendations yet")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .padding(.bottom, 6)
                    }
                }
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(hex: "#6B5440"), Color(hex: "#43331F")], startPoint: .top, endPoint: .bottom))
                    .frame(width: 230, height: 9)
            }
            .offset(y: bob ? -5 : 3)
            .background(alignment: .bottom) {
                Ellipse()
                    .fill(.black.opacity(bob ? 0.18 : 0.32))
                    .frame(width: bob ? 170 : 200, height: 12)
                    .blur(radius: 4)
                    .offset(y: 22)
            }
            .padding(.bottom, 20)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { bob = true }
            }

            Button("Add one", action: onAdd)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Palette.gold)
                .frame(minHeight: Theme.minTapTarget)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Books recommended to Omari, \(recommendations.count) total")
    }
}

#Preview {
    NavigationStack {
        DLShelfView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
