// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// A single book rendered as a narrow vertical spine, like a real book standing on a shelf.
struct BookSpineView: View {
    let book: Book
    var height: CGFloat = 160
    var isSelected: Bool = false

    var spineWidth: CGFloat {
        // Width loosely reflects page count so books feel like physical objects.
        min(52, max(30, 30 + CGFloat(book.pageCount) / 420 * 18))
    }

    var body: some View {
        let colors = Theme.coverGradient(book.cover.paletteIndex)
        ZStack {
            // Spine fill
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))

            // Binding-edge shadow
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(
                    colors: [.black.opacity(0.38), .clear],
                    startPoint: .leading,
                    endPoint: UnitPoint(x: 0.28, y: 0.5)
                ))

            // Vertical text — rotated VStack so title reads bottom-to-top
            VStack(spacing: 3) {
                Text(book.title)
                    .font(.system(size: 9.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.Palette.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: height - 24, alignment: .center)
                Text(book.author)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundStyle(Theme.Palette.parchment.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: height - 40, alignment: .center)
            }
            .rotationEffect(.degrees(-90))
            .frame(width: spineWidth, height: height)

            if isSelected {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(Theme.Palette.gold, lineWidth: 2)
            }
        }
        .frame(width: spineWidth, height: height)
        .shadow(color: .black.opacity(0.50), radius: 4, x: 2, y: 3)
        .accessibilityLabel("\(book.title) by \(book.author)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens book details")
    }
}

// MARK: - Shelf

/// Bottom-aligned row of spines on a wooden shelf surface, horizontally scrollable.
struct BookShelfRow: View {
    let books: [Book]
    var selectedBookID: UUID? = nil
    var emptyMessage: String = "No books on this shelf yet."
    var onSelect: (Book) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            if books.isEmpty {
                emptyShelf
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 5) {
                        ForEach(books) { book in
                            Button { onSelect(book) } label: {
                                BookSpineView(
                                    book: book,
                                    height: spineHeight(for: book),
                                    isSelected: selectedBookID == book.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }
            }
            shelfSurface
        }
    }

    // MARK: Sub-views

    private var emptyShelf: some View {
        Text(emptyMessage)
            .font(.bbCaption)
            .foregroundStyle(Theme.Palette.parchmentMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xl)
            .padding(.horizontal, Theme.Spacing.lg)
    }

    private var shelfSurface: some View {
        VStack(spacing: 0) {
            // Wood surface
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.40, green: 0.30, blue: 0.18),
                            Color(red: 0.24, green: 0.17, blue: 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 14)
                // Top highlight
                Color.white.opacity(0.12)
                    .frame(height: 2)
            }
            // Cast shadow below shelf
            LinearGradient(
                colors: [.black.opacity(0.32), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 10)
        }
    }

    // Height variation based on page count gives a realistic shelf feel.
    private func spineHeight(for book: Book) -> CGFloat {
        let base: CGFloat = 138
        let extra = CGFloat(book.pageCount) / 420 * 34
        return base + extra
    }
}

// MARK: - Previews

#Preview("Shelf") {
    BookShelfRow(books: DemoData.books, selectedBookID: DemoData.IDs.orbitOfAshes) { _ in }
        .padding(.vertical)
        .background(InkBackground())
}

#Preview("Empty shelf") {
    BookShelfRow(books: []) { _ in }
        .background(InkBackground())
}
