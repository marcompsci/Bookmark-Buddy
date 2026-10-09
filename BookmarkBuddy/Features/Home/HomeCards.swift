// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Current book

struct CurrentBookCard: View {
    let item: BookWithProgress
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                BookCoverPlaceholder(book: item.book, size: .medium, isDecorative: true)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("CURRENTLY READING")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.gold)
                    Text(item.book.title)
                        .font(.bbTitle)
                        .foregroundStyle(Theme.Palette.parchment)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.book.author)
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                    if let progress = item.progress {
                        Text("Chapter \(progress.currentChapter) of \(item.book.chapterCount)")
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchment)
                            .padding(.top, Theme.Spacing.xs)
                    }
                    Text("Fictional demo title")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                }
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ReadingProgressBar(fraction: item.fraction, label: "Progress in \(item.book.title)")
                Text("\(Int((item.fraction * 100).rounded()))% · \(item.progress?.pagesRead ?? 0) of \(item.book.pageCount) pages")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
            }

            PrimaryButton(title: "Continue", systemImage: "book.fill", action: onContinue)
                .accessibilityHint("Opens \(item.book.title)")
        }
        .bbCard()
    }
}

// MARK: - Pip's nudge

struct PipNudgeCard: View {
    let nudge: PipNudgeBuilder.Nudge
    let onAskPip: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            PipAvatar(size: 44, mood: .happy)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("\(PipIdentity.name)'s daily nudge")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.lavender)
                    .accessibilityAddTraits(.isHeader)
                Text(nudge.text)
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onAskPip) {
                    Label("Ask \(PipIdentity.name)", systemImage: "bubble.left.fill")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.gold)
                        .frame(minHeight: Theme.minTapTarget)
                }
                .accessibilityHint("Opens a chat with \(PipIdentity.name)")
            }
        }
        .bbCard(fill: Theme.Palette.inkHighlight)
    }
}

// MARK: - Upcoming event

struct UpcomingEventCard: View {
    let event: ReadingEvent
    let attendees: [SquadMember]
    let isAttending: Bool
    let isUpdating: Bool
    let onRSVP: () -> Void
    let onOpen: () -> Void

    private var whenText: String {
        event.startsAt.formatted(.dateTime.weekday(.wide).hour().minute())
    }

    private var relativeText: String {
        event.startsAt.formatted(.relative(presentation: .named))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    Image(systemName: event.type.symbol)
                        .font(.title2)
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(width: 48, height: 48)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.lavender))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UP NEXT")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.gold)
                        Text(event.title)
                            .font(.bbTitle3)
                            .foregroundStyle(Theme.Palette.parchment)
                        Text("\(whenText) · \(relativeText)")
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Shows event details")

            HStack(spacing: Theme.Spacing.md) {
                AvatarStack(members: attendees, size: 30)
                Text("\(attendees.count) going")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
                Spacer(minLength: Theme.Spacing.sm)
                rsvpButton
            }
        }
        .bbCard()
    }

    @ViewBuilder
    private var rsvpButton: some View {
        if isAttending {
            SecondaryButton(title: "Going", systemImage: "checkmark", fullWidth: false, action: onRSVP)
                .disabled(isUpdating)
                .accessibilityLabel("You're going to \(event.title)")
                .accessibilityHint("Double-tap to cancel your RSVP")
        } else {
            PrimaryButton(title: "RSVP", isLoading: isUpdating, fullWidth: false, action: onRSVP)
                .accessibilityHint("Lets your squad know you're coming")
        }
    }
}

// MARK: - Memory refresh

struct MemoryRefreshCard: View {
    let item: MemoryRefreshItem
    let phase: HomeViewModel.RefreshPhase
    let onStart: () -> Void
    let onAnswer: (Int) -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Theme.Palette.forestBright)
                    .accessibilityHidden(true)
                Text("Memory Refresh")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.forestBright)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(item.book.title)
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .lineLimit(1)
            }

            Text(item.question.prompt)
                .font(.bbTitle3)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)

            switch phase {
            case .collapsed:
                PrimaryButton(title: "Play now", systemImage: "play.fill", action: onStart)
            case .asking:
                options(selected: nil)
            case .answered(let selected, let correct):
                options(selected: selected)
                feedback(correct: correct)
                SecondaryButton(title: "Another question", systemImage: "arrow.clockwise", action: onNext)
            }
        }
        .bbCard()
    }

    private func options(selected: Int?) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(item.question.options.enumerated()), id: \.offset) { index, option in
                AnswerOptionButton(
                    text: option,
                    state: optionState(index: index, selected: selected),
                    action: { onAnswer(index) }
                )
                .disabled(selected != nil)
            }
        }
    }

    private func optionState(index: Int, selected: Int?) -> AnswerOptionButton.OptionState {
        guard let selected else { return .idle }
        if index == item.question.correctIndex { return .correct }
        if index == selected { return .incorrect }
        return .dimmed
    }

    private func feedback(correct: Bool) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            PipAvatar(size: 32, mood: correct ? .cheering : .thinking, animated: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(correct ? "Nice recall! Your memory of this book just grew." : "Close! Here's the answer:")
                    .font(.bbHeadline)
                    .foregroundStyle(correct ? Theme.Palette.forestBright : Theme.Palette.gold)
                Text(item.question.explanation)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Multiple-choice answer row, reused by the Play quiz in Phase 5.
struct AnswerOptionButton: View {
    enum OptionState {
        case idle, correct, incorrect, dimmed
    }

    let text: String
    let state: OptionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Text(text)
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment.opacity(state == .dimmed ? 0.6 : 1))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.inkHighlight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(state == .idle || state == .dimmed ? Theme.Palette.hairline : tint, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private var symbol: String? {
        switch state {
        case .correct: "checkmark.circle.fill"
        case .incorrect: "xmark.circle.fill"
        default: nil
        }
    }

    private var tint: Color {
        switch state {
        case .correct: Theme.Palette.forestBright
        case .incorrect: Theme.Palette.danger
        default: Theme.Palette.hairline
        }
    }

    private var accessibilityText: String {
        switch state {
        case .correct: "\(text), correct answer"
        case .incorrect: "\(text), your answer, incorrect"
        default: text
        }
    }
}

// MARK: - Quick actions

struct QuickActionsRow: View {
    let onQuiz: () -> Void
    let onCreateEvent: () -> Void
    let onAskPip: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // TODO(prod): Replace with a signed, expiring invite link generated server-side.
    private let inviteMessage = "Join me on Bookmark Buddy — we read together, quiz each other and actually remember our books. (Demo invite, no link yet.)"

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        return Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.sm), count: count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Quick actions")
            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                QuickActionTile(title: "Start a quiz", systemImage: "bolt.fill", action: onQuiz)
                // The system share sheet is the explicit confirmation step: nothing is sent
                // unless the person picks a recipient and sends it themselves.
                ShareLink(item: inviteMessage) {
                    QuickActionTileLabel(title: "Invite a friend", systemImage: "person.badge.plus")
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the share sheet. Nothing is sent until you choose to send it.")
                QuickActionTile(title: "Create event", systemImage: "calendar.badge.plus", action: onCreateEvent)
                QuickActionTile(title: "Ask \(PipIdentity.name)", systemImage: "sparkles", action: onAskPip)
            }
        }
    }
}

private struct QuickActionTile: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionTileLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionTileLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.Palette.gold)
                .accessibilityHidden(true)
            Text(title)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchment)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.xs)
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.inkRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Squad activity

struct SquadActivityCard: View {
    let squad: ReadingSquad
    let items: [ActivityFeedItem]
    let member: (UUID) -> SquadMember?
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Squad activity", subtitle: squad.name, actionTitle: "See all", action: onSeeAll)
            if items.isEmpty {
                Text("It's quiet in \(squad.name) right now.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        ActivityRow(item: item, member: member(item.memberID))
                        if item.id != items.last?.id {
                            Divider().overlay(Theme.Palette.hairline)
                        }
                    }
                }
                .bbCard(padding: Theme.Spacing.md)
            }
        }
    }
}

/// One line of squad activity. Reused by the Squad tab in Phase 6.
struct ActivityRow: View {
    let item: ActivityFeedItem
    let member: SquadMember?

    private var name: String {
        guard let member else { return "A former member" }
        return member.isCurrentUser ? "You" : member.displayName
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            MemberAvatar(
                name: member?.displayName ?? "?",
                seed: member?.avatarSeed ?? 0,
                size: 36,
                isCurrentUser: member?.isCurrentUser ?? false
            )
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Text(name).bold()) \(item.message)")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: item.kind.symbol)
                        .accessibilityHidden(true)
                    Text(item.timestamp.formatted(.relative(presentation: .named)))
                    if item.reactionCount > 0 {
                        Text("· \(item.reactionCount) cheers")
                    }
                }
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 20) {
            if let book = DemoData.books.first(where: { $0.id == DemoData.IDs.orbitOfAshes }) {
                CurrentBookCard(item: BookWithProgress(book: book, progress: DemoData.progress.first), onContinue: {})
            }
            PipNudgeCard(nudge: .init(text: "One chapter tonight keeps your 12-day streak going.", action: nil), onAskPip: {})
            if let event = DemoData.events.first {
                UpcomingEventCard(event: event, attendees: Array(DemoData.members.prefix(3)), isAttending: false, isUpdating: false, onRSVP: {}, onOpen: {})
            }
            if let book = PreviewFixtures.glassHarbor, let question = DemoData.refreshQuestions[book.id]?.first {
                MemoryRefreshCard(item: MemoryRefreshItem(book: book, question: question), phase: .answered(selected: 1, correct: false), onStart: {}, onAnswer: { _ in }, onNext: {})
            }
            QuickActionsRow(onQuiz: {}, onCreateEvent: {}, onAskPip: {})
        }
        .padding()
    }
    .background(InkBackground())
    .preferredColorScheme(.dark)
}

// MARK: - Memory Garden teaser (Home)

struct MemoryGardenTeaser: View {
    let onSeeGarden: () -> Void
    @Environment(\.services) private var services
    @State private var entries: [MemoryGardenEntry] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if hasLoaded && !entries.isEmpty {
                cardContent
            }
        }
        .task {
            entries = (try? await services.quizzes.memoryGarden()) ?? []
            hasLoaded = true
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Theme.Palette.forestBright)
                    .accessibilityHidden(true)
                Text("Memory Garden")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.forestBright)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(entries.count) plant\(entries.count == 1 ? "" : "s")")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }

            let avg = entries.map(\.strength).reduce(0, +) / Double(entries.count)
            HStack(alignment: .bottom, spacing: Theme.Spacing.md) {
                ForEach(entries.prefix(3)) { entry in
                    PlantShape(strength: entry.strength)
                        .frame(width: 40, height: 56)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: 0)
                Text("\(Int((avg * 100).rounded()))% avg. memory")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .multilineTextAlignment(.trailing)
            }

            SecondaryButton(title: "See your garden", systemImage: "leaf.fill", action: onSeeGarden)
        }
        .bbCard()
    }
}

// MARK: - Digital Library welcome

struct DigitalLibraryWelcome: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Welcome to your")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .textCase(.uppercase)
                .tracking(1.2)
            Text("Digital Library")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Palette.parchment, Theme.Palette.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Find your Bookmark Buddy here!")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.lavender)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Personal spine shelf (home)

struct PersonalSpineShelf: View {
    let content: HomeViewModel.Content
    var isWiggling: Bool = false
    let onSelect: (Book) -> Void

    @Environment(LibraryCustomization.self) private var customization

    var body: some View {
        let theme = customization.activeTheme
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Your Shelf")
                    .font(.bbHeadline)
                    .foregroundStyle(theme.shelfLabelColor)
                Spacer()
                Text("\(content.shelfBooks.count) books")
                    .font(.bbCaption)
                    .foregroundStyle(theme.shelfSubLabelColor)
            }
            .padding(.horizontal, Theme.Spacing.xs)

            ThemedBookShelfRow(
                books: content.shelfBooks,
                theme: theme,
                spineStyle: customization.spineStyle,
                isWiggling: isWiggling,
                selectedBookID: content.current?.book.id,
                emptyMessage: "Books you're reading and have finished will appear here.",
                onSelect: onSelect
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your reading shelf")
    }
}

#Preview("Digital Library Welcome") {
    DigitalLibraryWelcome()
        .padding()
        .background(InkBackground())
        .preferredColorScheme(.dark)
}
