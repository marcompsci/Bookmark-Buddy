// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// "Books You Still Remember": each finished book is a plant that grows with correct refresh answers.
struct MemoryGardenView: View {
    let entries: [MemoryGardenEntry]
    let onSelect: (MemoryGardenEntry) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.sm), count: count)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
            ForEach(entries) { entry in
                Button {
                    onSelect(entry)
                } label: {
                    GardenPlot(entry: entry)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(entry.book.title), memory \(Int((entry.strength * 100).rounded())) percent, \(MemoryStrength(entry.strength).label)")
                .accessibilityHint("Answers one question to refresh this book")
            }
        }
    }
}

enum MemoryStrength {
    case fading, growing, strong, blooming

    init(_ value: Double) {
        switch value {
        case ..<0.3: self = .fading
        case ..<0.6: self = .growing
        case ..<0.85: self = .strong
        default: self = .blooming
        }
    }

    var label: String {
        switch self {
        case .fading: "Fading"
        case .growing: "Growing"
        case .strong: "Strong"
        case .blooming: "Blooming"
        }
    }

    var tint: Color {
        switch self {
        case .fading: Theme.Palette.lavender
        case .growing: Theme.Palette.forestBright
        case .strong: Theme.Palette.forestBright
        case .blooming: Theme.Palette.gold
        }
    }
}

private struct GardenPlot: View {
    let entry: MemoryGardenEntry

    var body: some View {
        let strength = MemoryStrength(entry.strength)
        VStack(spacing: Theme.Spacing.xs) {
            PlantShape(strength: entry.strength)
                .frame(height: 96)
            Text(entry.book.title)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchment)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
            Text(strength.label)
                .font(.bbCaption)
                .foregroundStyle(strength.tint)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.inkRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}

/// A potted plant drawn with shapes. Stem height and leaf count grow with strength;
/// a gold bloom appears once the memory is strong.
struct PlantShape: View {
    let strength: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let potHeight = height * 0.26
            let clamped = min(1, max(0, strength))
            let stemHeight = (height - potHeight) * (0.25 + 0.7 * clamped)
            let leafCount = 1 + Int(clamped * 4)
            let wilted = clamped < 0.3
            let stemTop = height - potHeight - stemHeight

            ZStack(alignment: .bottom) {
                // Stem
                Capsule()
                    .fill(wilted ? Theme.Palette.lavender.opacity(0.7) : Theme.Palette.forestBright)
                    .frame(width: 4, height: stemHeight)
                    .position(x: width / 2, y: height - potHeight - stemHeight / 2)

                // Leaves, alternating sides up the stem
                ForEach(0..<leafCount, id: \.self) { index in
                    let fraction = CGFloat(index + 1) / CGFloat(leafCount + 1)
                    let y = height - potHeight - stemHeight * fraction
                    let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                    Ellipse()
                        .fill(wilted ? Theme.Palette.lavender.opacity(0.6) : Theme.Palette.forestBright)
                        .frame(width: 16, height: 8)
                        .rotationEffect(.degrees(side * (wilted ? 40 : -25)))
                        .position(x: width / 2 + side * 9, y: y)
                }

                // Bloom
                if clamped >= 0.6 {
                    ZStack {
                        ForEach(0..<5, id: \.self) { petal in
                            Ellipse()
                                .fill(clamped >= 0.85 ? Theme.Palette.gold : Theme.Palette.parchment.opacity(0.85))
                                .frame(width: 9, height: 14)
                                .offset(y: -6)
                                .rotationEffect(.degrees(Double(petal) * 72))
                        }
                        Circle()
                            .fill(Theme.Palette.ink)
                            .frame(width: 6, height: 6)
                    }
                    .position(x: width / 2, y: stemTop)
                }

                // Pot
                PotShape()
                    .fill(Theme.Palette.forest)
                    .frame(width: min(width * 0.55, 56), height: potHeight)
                    .position(x: width / 2, y: height - potHeight / 2)
            }
        }
        .accessibilityHidden(true)
    }
}

struct PotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.14
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Refresh one plant

/// A single refresh question for one garden book, presented as a sheet.
struct GardenRefreshSheet: View {
    let book: Book

    @Environment(\.services) private var services
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var item: MemoryRefreshItem?
    @State private var phase: HomeViewModel.RefreshPhase = .asking
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let item {
                        MemoryRefreshCard(
                            item: item,
                            phase: phase,
                            onStart: { phase = .asking },
                            onAnswer: { index in answer(index, item: item) },
                            onNext: { Task { await loadNext() } }
                        )
                    } else if failed {
                        EmptyStateView(systemImage: "leaf", title: "No question yet", message: "There isn't a refresh question for this book right now.")
                    } else {
                        LoadingCard(label: "Loading a question", lines: 4)
                    }
                    if book.source == .personalShelf {
                        Label("Questions about your shelf use titles and authors only.", systemImage: "info.circle")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(InkBackground())
            .navigationTitle("Refresh a memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        router.dataChanged()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .task { await loadNext() }
    }

    private func answer(_ index: Int, item: MemoryRefreshItem) {
        guard phase == .asking else { return }
        let correct = item.question.isCorrect(index)
        phase = .answered(selected: index, correct: correct)
        Task { await services.quizzes.recordRefresh(bookID: item.book.id, wasCorrect: correct) }
    }

    private func loadNext() async {
        phase = .asking
        do {
            item = try await services.quizzes.refreshItem(for: book.id)
            failed = item == nil
        } catch {
            failed = true
        }
    }
}

#Preview("Garden") {
    ScrollView {
        MemoryGardenView(
            entries: [0.1, 0.35, 0.55, 0.7, 0.9, 1.0].enumerated().compactMap { index, strength in
                (DemoData.books + PersonalShelf.books)[safe: index].map {
                    MemoryGardenEntry(book: $0, strength: strength, lastRefreshed: nil)
                }
            },
            onSelect: { _ in }
        )
        .padding()
    }
    .background(InkBackground())
    .preferredColorScheme(.dark)
}
