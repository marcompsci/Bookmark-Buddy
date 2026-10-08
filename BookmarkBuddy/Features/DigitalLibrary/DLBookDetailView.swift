// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// A Digital Library book: original cover, typewriter title, description, quotes with
/// "why it is powerful" notes, expandable panels, and facts. Swipe between books.
struct DLBookDetailView: View {
    let bookID: String

    @Environment(\.dismiss) private var dismiss
    @State private var selection: String = ""

    private var books: [DLBook] { DLCatalog.books }
    private var index: Int { books.firstIndex { $0.id == selection } ?? 0 }

    var body: some View {
        ZStack {
            InkBackground()
            if books.isEmpty {
                EmptyStateView(systemImage: "books.vertical", title: "No books", message: "The Digital Library data couldn't be loaded.")
            } else {
                TabView(selection: $selection) {
                    ForEach(books) { book in
                        DLBookPage(book: book, isCurrent: book.id == selection)
                            .tag(book.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle(books.indices.contains(index) ? books[index].title : "")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !books.isEmpty { pager }
        }
        .onAppear {
            if selection.isEmpty { selection = bookID }
        }
    }

    private var pager: some View {
        HStack {
            Button {
                withAnimation { selection = books[max(index - 1, 0)].id }
            } label: {
                Label("Previous", systemImage: "arrow.left")
            }
            .disabled(index == 0)
            Spacer()
            VStack(spacing: 2) {
                Text("\(index + 1) / \(books.count)")
                    .font(.system(.caption, design: .monospaced))
                Text("or swipe")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Book \(index + 1) of \(books.count)")
            Spacer()
            Button {
                withAnimation { selection = books[min(index + 1, books.count - 1)].id }
            } label: {
                Label("Next", systemImage: "arrow.right")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .disabled(index >= books.count - 1)
        }
        .font(.system(.callout, design: .monospaced).weight(.semibold))
        .foregroundStyle(Theme.Palette.parchment)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Button("Shelve it") { dismiss() }
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Theme.Palette.gold)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.Palette.inkRaised))
                .offset(y: -18)
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

/// One page: everything about one book.
private struct DLBookPage: View {
    let book: DLBook
    let isCurrent: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var coverAngle: Double = 78
    @State private var openPanel: DLPanelKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                DLCoverView(book: book, width: 210)
                    .rotation3DEffect(.degrees(coverAngle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Theme.Spacing.lg)

                info
                if !book.quotes.isEmpty { quotes }
                if !book.panels.available.isEmpty { panels }
                facts
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 80)
        }
        .onChange(of: isCurrent, initial: true) { _, current in
            guard current else { return }
            if reduceMotion {
                coverAngle = 0
            } else {
                coverAngle = 78
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { coverAngle = 0 }
            }
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            DLEyebrow(text: "\(book.genre) · \(book.year)")
            if isCurrent {
                DLTypewriterText(text: book.title, font: .system(.title, design: .serif).italic(), speed: 0.034, startDelay: 0.2)
            } else {
                Text(book.title).font(.system(.title, design: .serif).italic()).foregroundStyle(Theme.Palette.parchment)
            }
            if let subtitle = book.subtitle {
                Text(subtitle)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            Text(book.authorNote.map { "\(book.author), \($0)" } ?? book.author)
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(Theme.Palette.gold)
            Text(book.description)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    private var quotes: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            DLEyebrow(text: "Quotes")
            ForEach(book.quotes, id: \.self) { quote in
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("“\(quote.text)”")
                        .font(.system(.title3, design: .serif).italic())
                        .foregroundStyle(Theme.Palette.parchment)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, Theme.Spacing.md)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Color(hex: book.spine.accent)).frame(width: 3)
                        }
                    if let why = quote.why {
                        VStack(alignment: .leading, spacing: 4) {
                            DLEyebrow(text: "Why it is powerful", color: Theme.Palette.gold)
                            Text(why)
                                .font(.bbCallout)
                                .foregroundStyle(Theme.Palette.parchmentMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Theme.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkRaised))
                    }
                }
            }
        }
    }

    private var panels: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(book.panels.available) { panel in
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                            openPanel = openPanel == panel.kind ? nil : panel.kind
                        }
                    } label: {
                        HStack {
                            Text(panel.kind.title.uppercased())
                                .font(.system(.caption, design: .monospaced).weight(.semibold))
                                .tracking(1.5)
                            Spacer()
                            Image(systemName: openPanel == panel.kind ? "minus" : "plus")
                        }
                        .foregroundStyle(Theme.Palette.parchment)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(minHeight: Theme.minTapTarget)
                        .background(Capsule().strokeBorder(Theme.Palette.parchment.opacity(0.4), lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(openPanel == panel.kind ? "Expanded" : "Collapsed")

                    if openPanel == panel.kind {
                        DLPanelContent(blocks: panel.blocks, accent: Color(hex: book.spine.accent))
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    private var facts: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.lg) {
            fact("Published", "\(book.year)")
            if let first = book.firstPublished { fact("First edition", "\(first)") }
            fact("Publisher", book.publisher)
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            DLEyebrow(text: label)
            Text(verbatim: value)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchment)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Renders panel blocks; table rows become a clean two-column grid.
private struct DLPanelContent: View {
    let blocks: [DLBlock]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block.kind {
                case .heading:
                    Text(rich(block.text)).font(.system(.title3, design: .serif).italic())
                        .foregroundStyle(Theme.Palette.parchment)
                case .subheading:
                    Text(rich(block.text)).font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.parchment)
                        .padding(.top, Theme.Spacing.xs)
                case .quoteHeading:
                    VStack(alignment: .leading, spacing: 2) {
                        if let detail = block.detail {
                            Text(detail).font(.system(.callout, design: .serif).italic()).foregroundStyle(accent)
                        }
                        Text(rich(block.text)).font(.bbHeadline).foregroundStyle(Theme.Palette.parchment)
                    }
                    .padding(.top, Theme.Spacing.xs)
                case .paragraph:
                    Text(rich(block.text)).font(.bbBody).foregroundStyle(Theme.Palette.parchmentMuted)
                        .fixedSize(horizontal: false, vertical: true)
                case .bullet:
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                        Circle().fill(accent).frame(width: 5, height: 5).accessibilityHidden(true)
                        Text(rich(block.text)).font(.bbBody).foregroundStyle(Theme.Palette.parchmentMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .tableHeader, .row:
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Text(rich(block.text))
                            .font(block.kind == .tableHeader ? .system(.caption, design: .monospaced).weight(.semibold) : .bbHeadline)
                            .foregroundStyle(block.kind == .tableHeader ? Theme.Palette.gold : Theme.Palette.parchment)
                            .frame(width: 110, alignment: .leading)
                        Text(rich(block.detail ?? ""))
                            .font(block.kind == .tableHeader ? .system(.caption, design: .monospaced).weight(.semibold) : .bbCallout)
                            .foregroundStyle(block.kind == .tableHeader ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) { Rectangle().fill(Theme.Palette.hairline).frame(height: 1) }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.Palette.inkRaised))
    }

    /// Panel copy is Omari's own, so **bold** and *italic* markdown is allowed here.
    private func rich(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

#Preview {
    NavigationStack {
        DLBookDetailView(bookID: "money-works")
    }
    .withPreviewEnvironment()
}
