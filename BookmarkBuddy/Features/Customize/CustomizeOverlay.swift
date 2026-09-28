// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Entry point called from HomeView

/// Full-screen library customization overlay.
/// Trigger: long-press on Home → haptic → this view appears with a spring entrance.
struct CustomizeOverlay: View {
    @Binding var isPresented: Bool
    @Environment(LibraryCustomization.self) private var customization
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Staging state so changes preview live but only commit on "Done"
    @State private var draftThemeID: String = ""
    @State private var draftAccentID: String = ""
    @State private var draftSpineStyle: SpineDisplayStyle = .classic
    @State private var appeared = false

    private let sampleBooks = Array(DemoData.books.prefix(6))

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Frosted backdrop ──────────────────────────────────────────
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // ── Floating panel ────────────────────────────────────────────
            VStack(spacing: 0) {
                dragIndicator
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xl) {
                        headerRow
                        livePreview
                        themePicker
                        accentPicker
                        spineStylePicker
                        doneButton
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.45), radius: 32, y: -8)
            .padding(.horizontal, 6)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.82)
            .offset(y: appeared ? 0 : UIScreen.main.bounds.height)
        }
        .ignoresSafeArea()
        .onAppear {
            draftThemeID   = customization.themeID
            draftAccentID  = customization.accentColorID
            draftSpineStyle = customization.spineStyle
            withAnimation(reduceMotion ? nil : .spring(response: 0.52, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    // MARK: Sub-views

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.25))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
            PipAvatar(size: 34, mood: .happy, animated: !reduceMotion)
            VStack(alignment: .leading, spacing: 2) {
                Text("Customize Library")
                    .font(.bbTitle3)
                    .foregroundStyle(.primary)
                Text("Pick a look that fits your reading world.")
                    .font(.bbCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close customization")
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // ── Live shelf preview ───────────────────────────────────────────────

    private var livePreview: some View {
        let theme = previewTheme
        return VStack(spacing: 0) {
            // Shelf area with dynamic background
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: theme.shelfBackgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                ThemedBookShelfRow(
                    books: sampleBooks,
                    theme: theme,
                    spineStyle: draftSpineStyle,
                    isWiggling: false
                )
                .allowsHitTesting(false)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )

            // Preview label
            HStack {
                Text("Live Preview")
                    .font(.bbCaption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label(previewTheme.name, systemImage: "checkmark.circle.fill")
                    .font(.bbCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    // ── Theme preset picker ──────────────────────────────────────────────

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel(title: "THEME")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(LibraryThemeData.presets) { preset in
                        ThemePresetTile(
                            preset: preset,
                            isSelected: draftThemeID == preset.id
                        ) {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                                draftThemeID = preset.id
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
                .padding(.horizontal, 2)
            }
        }
    }

    // ── Accent color picker ──────────────────────────────────────────────

    private var accentPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel(title: "ACCENT COLOR")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.md), count: 4), spacing: Theme.Spacing.md) {
                ForEach(LibraryThemeData.accentColors) { entry in
                    AccentSwatch(
                        entry: entry,
                        isSelected: draftAccentID == entry.id
                    ) {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.65)) {
                            draftAccentID = entry.id
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
    }

    // ── Spine style picker ───────────────────────────────────────────────

    private var spineStylePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel(title: "SPINE STYLE")
            HStack(spacing: Theme.Spacing.md) {
                ForEach(SpineDisplayStyle.allCases) { style in
                    SpineStyleTile(
                        style: style,
                        isSelected: draftSpineStyle == style
                    ) {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7)) {
                            draftSpineStyle = style
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
    }

    // ── Done button ──────────────────────────────────────────────────────

    private var doneButton: some View {
        Button {
            applyAndDismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Apply")
                    .font(.bbHeadline)
            }
            .foregroundStyle(Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        LibraryThemeData.accentColors.first { $0.id == draftAccentID }?.color ?? Theme.Palette.gold,
                        (LibraryThemeData.accentColors.first { $0.id == draftAccentID }?.color ?? Theme.Palette.gold).opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Apply customization")
    }

    // MARK: Helpers

    private var previewTheme: ShelfThemePreset {
        LibraryThemeData.presets.first { $0.id == draftThemeID } ?? LibraryThemeData.inkWorld
    }

    private func applyAndDismiss() {
        customization.themeID      = draftThemeID
        customization.accentColorID = draftAccentID
        customization.spineStyle   = draftSpineStyle
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private func dismiss() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.82)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isPresented = false
        }
    }
}

// MARK: - ThemedBookShelfRow (preview + final render)

/// `BookShelfRow` variant that accepts an explicit `ShelfThemePreset` and `SpineDisplayStyle`,
/// and optionally wiggles the spines (long-press customization mode entrance).
struct ThemedBookShelfRow: View {
    let books: [Book]
    var theme: ShelfThemePreset
    var spineStyle: SpineDisplayStyle = .classic
    var isWiggling: Bool = false
    var selectedBookID: UUID? = nil
    var emptyMessage: String = "No books on this shelf yet."
    var onSelect: (Book) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            if books.isEmpty {
                Text(emptyMessage)
                    .font(.bbCaption)
                    .foregroundStyle(theme.shelfLabelColor.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    TimelineView(.animation(minimumInterval: 1/30, paused: !isWiggling)) { ctx in
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        HStack(alignment: .bottom, spacing: 5) {
                            ForEach(Array(books.enumerated()), id: \.element.id) { idx, book in
                                let wiggleAngle = isWiggling
                                    ? 1.8 * sin(t * 9.5 + Double(idx) * 0.75)
                                    : 0.0
                                Button { onSelect(book) } label: {
                                    StyledSpineView(
                                        book: book,
                                        style: spineStyle,
                                        height: spineHeight(for: book),
                                        isSelected: selectedBookID == book.id,
                                        highlightOpacity: theme.spineHighlightOpacity
                                    )
                                    .rotationEffect(.degrees(wiggleAngle), anchor: .bottom)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }
                }
            }
            // Shelf surface
            themedShelfSurface
        }
    }

    private var themedShelfSurface: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [theme.woodTopColor, theme.woodBottomColor],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(height: 14)
                Color.white.opacity(0.14).frame(height: 2)
            }
            LinearGradient(
                colors: [.black.opacity(0.30), .clear],
                startPoint: .top, endPoint: .bottom
            ).frame(height: 10)
        }
    }

    private func spineHeight(for book: Book) -> CGFloat {
        138 + CGFloat(book.pageCount) / 420 * 34
    }
}

// MARK: - StyledSpineView

/// Renders a spine with one of three styles.
struct StyledSpineView: View {
    let book: Book
    var style: SpineDisplayStyle = .classic
    var height: CGFloat = 160
    var isSelected: Bool = false
    var highlightOpacity: Double = 0.38

    private var spineWidth: CGFloat {
        min(52, max(30, 30 + CGFloat(book.pageCount) / 420 * 18))
    }

    var body: some View {
        let palette = Theme.coverGradient(book.cover.paletteIndex)
        let baseColor = palette.first ?? .gray
        let darkColor = palette.last ?? .black

        ZStack {
            // Fill based on style
            switch style {
            case .classic:
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(colors: palette, startPoint: .leading, endPoint: .trailing))
                // Binding shadow
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.black.opacity(highlightOpacity), .clear],
                        startPoint: .leading,
                        endPoint: UnitPoint(x: 0.28, y: 0.5)
                    ))
            case .minimal:
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(baseColor.opacity(0.92))
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(darkColor.opacity(0.35), lineWidth: 1)
            case .vivid:
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(
                        colors: [baseColor, darkColor, baseColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                // Bright highlight stripe
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.45), .clear],
                        startPoint: .leading,
                        endPoint: UnitPoint(x: 0.18, y: 0.5)
                    ))
            }

            // Rotated title text
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

// MARK: - Tiles & swatches

private struct ThemePresetTile: View {
    let preset: ShelfThemePreset
    let isSelected: Bool
    let onTap: () -> Void

    private let miniBooks: [Book] = Array(DemoData.books.prefix(4))

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.sm) {
                // Mini shelf preview
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: preset.shelfBackgroundColors,
                        startPoint: .top, endPoint: .bottom
                    )
                    miniShelf
                }
                .frame(width: 108, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Theme.Palette.gold : Color.white.opacity(0.12),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                )
                .shadow(color: .black.opacity(0.28), radius: 6, y: 3)
                .scaleEffect(isSelected ? 1.04 : 1.0)

                // Label
                VStack(spacing: 2) {
                    Text(preset.emoji + " " + preset.name)
                        .font(.bbCaption)
                        .foregroundStyle(.primary)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.Palette.gold)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 108)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.name) theme\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var miniShelf: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(miniBooks.enumerated()), id: \.element.id) { idx, book in
                    let colors = Theme.coverGradient(book.cover.paletteIndex)
                    let w: CGFloat = [14, 10, 12, 11][idx % 4]
                    let h: CGFloat = [52, 44, 56, 48][idx % 4]
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: w, height: h)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 1, y: 1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            // Tiny shelf
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [preset.woodTopColor, preset.woodBottomColor],
                    startPoint: .top, endPoint: .bottom
                ).frame(height: 7)
                Color.white.opacity(0.18).frame(height: 1.5)
            }
            LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 5)
        }
    }
}

private struct AccentSwatch: View {
    let entry: AccentColorEntry
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(entry.color)
                    .frame(width: 52, height: 52)
                    .shadow(color: entry.color.opacity(0.6), radius: isSelected ? 8 : 3, y: 2)
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 52, height: 52)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(entry.onColor)
                        .transition(.scale)
                }
            }
            .scaleEffect(isSelected ? 1.12 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.name) accent color\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct SpineStyleTile: View {
    let style: SpineDisplayStyle
    let isSelected: Bool
    let onTap: () -> Void

    private let book: Book = DemoData.books[0]

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.sm) {
                StyledSpineView(
                    book: book,
                    style: style,
                    height: 80,
                    highlightOpacity: 0.35
                )
                .frame(width: 28, height: 80)
                .scaleEffect(isSelected ? 1.06 : 1.0)

                Text(style.label)
                    .font(.bbCaption)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                            .strokeBorder(
                                isSelected ? Theme.Palette.gold.opacity(0.8) : Color.white.opacity(0.10),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.label) spine style\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(1.4)
    }
}

// MARK: - Preview

#Preview("Customize Overlay") {
    ZStack {
        InkBackground()
        CustomizeOverlay(isPresented: .constant(true))
    }
    .environment(LibraryCustomization())
    .withPreviewEnvironment()
}
