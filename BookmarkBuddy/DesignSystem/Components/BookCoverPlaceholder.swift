// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Original generated cover art: gradient, geometric motif and serif title.
/// Never uses real cover images.
struct BookCoverPlaceholder: View {
    enum Size {
        case small, medium, large

        var width: CGFloat {
            switch self {
            case .small: 56
            case .medium: 92
            case .large: 150
            }
        }

        var height: CGFloat { width * 1.5 }
    }

    let book: Book
    var size: Size = .medium
    /// Set true when the title is already shown next to the cover, so VoiceOver doesn't repeat it.
    var isDecorative = false

    var body: some View {
        let colors = Theme.coverGradient(book.cover.paletteIndex)
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            // Concentric rings for texture
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(Theme.Palette.parchment.opacity(0.08), lineWidth: 1)
                    .frame(width: size.width * (0.7 + CGFloat(ring) * 0.35))
                    .offset(x: size.width * 0.35, y: -size.height * 0.25)
            }

            Image(systemName: book.cover.motif.symbol)
                .font(.system(size: size.width * 0.34, weight: .light))
                .foregroundStyle(Theme.Palette.parchment.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -size.height * 0.1)

            // Spine highlight
            Rectangle()
                .fill(Theme.Palette.parchment.opacity(0.12))
                .frame(width: max(2, size.width * 0.05))
                .frame(maxHeight: .infinity)

            if size != .small {
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.system(size: size.width * 0.12, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.Palette.parchment)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                    Text(book.author.uppercased())
                        .font(.system(size: size.width * 0.075, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Palette.parchment.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(size.width * 0.1)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
                .strokeBorder(Theme.Palette.parchment.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Illustrated cover for \(book.title)")
        .accessibilityHidden(isDecorative)
        // Cover text is decorative art; it intentionally doesn't scale with Dynamic Type.
        .dynamicTypeSize(.large)
    }
}

#Preview {
    HStack(alignment: .bottom, spacing: 16) {
        ForEach(DemoData.books.prefix(3)) { book in
            BookCoverPlaceholder(book: book, size: .medium)
        }
        if let first = DemoData.books.first {
            BookCoverPlaceholder(book: first, size: .small)
        }
    }
    .padding()
    .background(InkBackground())
}
