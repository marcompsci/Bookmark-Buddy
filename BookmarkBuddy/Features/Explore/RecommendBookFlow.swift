// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Sheet flow: pick a book from the library and write an optional note,
/// then post it to the community recommended shelf.
struct RecommendBookFlow: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    @State private var selectedBook: Book? = nil
    @State private var note: String = ""
    @State private var isPosting = false
    @State private var didPost = false

    private let books = DemoData.books

    var body: some View {
        ZStack {
            InkBackground()
            if didPost {
                successView
            } else {
                form
            }
        }
        .navigationTitle("Recommend a Book")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                headerText

                // Book picker
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader(title: "Pick a book")
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(books) { book in
                            BookPickRow(
                                book: book,
                                isSelected: selectedBook?.id == book.id
                            ) {
                                selectedBook = selectedBook?.id == book.id ? nil : book
                            }
                        }
                    }
                }

                // Note field
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    SectionHeader(title: "Why do you recommend it? (optional)")
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .fill(Theme.Palette.inkRaised)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.md)
                                    .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
                            )
                        if note.isEmpty {
                            Text("Tell the community why they should read it…")
                                .font(.bbBody)
                                .foregroundStyle(Theme.Palette.parchmentMuted)
                                .padding(Theme.Spacing.md)
                        }
                        TextEditor(text: $note)
                            .font(.bbBody)
                            .foregroundStyle(Theme.Palette.parchment)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90)
                            .padding(Theme.Spacing.sm)
                    }
                    .frame(minHeight: 110)
                }

                PrimaryButton(
                    title: "Add to Community Shelf",
                    systemImage: "sparkles",
                    isLoading: isPosting
                ) {
                    Task { await post() }
                }
                .disabled(selectedBook == nil || isPosting)

                Text("Your recommendation will be visible to other readers in this demo. Nothing is sent to a server.")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .padding(.bottom, Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Share a great read")
                .font(.bbTitle)
                .foregroundStyle(Theme.Palette.parchment)
            Text("Pick a book and let the community know why it's worth reading.")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            PipAvatar(size: 72, mood: .cheering)
            VStack(spacing: Theme.Spacing.sm) {
                Text("Recommendation added!")
                    .font(.bbTitle)
                    .foregroundStyle(Theme.Palette.parchment)
                if let book = selectedBook {
                    Text("\(book.title) is on the Community shelf.")
                        .font(.bbBody)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .multilineTextAlignment(.center)
                }
            }
            PrimaryButton(title: "View Community Shelf", systemImage: "books.vertical") {
                router.dismissSheet()
                router.push(.recommendedShelf, in: .explore)
                router.select(.explore)
            }
            SecondaryButton(title: "Done") {
                router.dismissSheet()
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Action

    private func post() async {
        guard let book = selectedBook, let profile = appState.profile else { return }
        isPosting = true
        // Simulate a brief async pause.
        try? await Task.sleep(for: .milliseconds(600))
        let rec = BookRecommendation(
            bookID: book.id,
            recommenderID: profile.id,
            recommenderName: profile.displayName,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
            createdAt: .now
        )
        let store = LocalStore()
        var saved = store.load([BookRecommendation].self, key: "communityRecommendations") ?? []
        saved.insert(rec, at: 0)
        try? store.save(saved, key: "communityRecommendations")
        router.dataChanged()
        isPosting = false
        withAnimation { didPost = true }
    }
}

// MARK: - BookPickRow

private struct BookPickRow: View {
    let book: Book
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
            }
            .bbCard(padding: Theme.Spacing.md, fill: isSelected ? Theme.Palette.inkHighlight : Theme.Palette.inkRaised)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(book.title) by \(book.author)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    NavigationStack {
        RecommendBookFlow()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") {} }
            }
    }
    .withPreviewEnvironment()
}
