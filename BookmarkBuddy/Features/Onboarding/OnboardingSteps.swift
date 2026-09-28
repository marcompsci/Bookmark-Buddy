// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - 1. Welcome

struct WelcomeStepView: View {
    @Bindable var model: OnboardingViewModel
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            HStack {
                Spacer()
                PipAvatar(size: 104, mood: .happy)
                Spacer()
            }
            .padding(.top, Theme.Spacing.md)

            OnboardingStepTitle(
                title: "Read together.\nRemember more.",
                subtitle: "Bookmark Buddy turns reading into a shared game: small squads, playful quizzes, and a companion named \(PipIdentity.name) who helps you hold on to every story."
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                FeatureRow(systemImage: "person.3.fill", title: "Read with a small squad", detail: "Buddy reads, trivia nights and gentle nudges.")
                FeatureRow(systemImage: "brain.head.profile", title: "Remember what you read", detail: "Quick refresh quizzes grow your Memory Garden.")
                FeatureRow(systemImage: "sparkles", title: "Meet \(PipIdentity.name)", detail: "Your guide inside this app — never outside it.")
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("What should \(PipIdentity.name) call you?")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                TextField(
                    "",
                    text: $model.displayName,
                    prompt: Text("First name (optional)").foregroundStyle(Theme.Palette.parchmentMuted)
                )
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($nameFocused)
                .onSubmit { nameFocused = false }
                .onChange(of: model.displayName) { model.enforceNameLimit() }
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(.horizontal, Theme.Spacing.lg)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.Palette.inkRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(nameFocused ? Theme.Palette.gold : Theme.Palette.hairline, lineWidth: nameFocused ? 2 : 1)
                )
                .accessibilityLabel("Your first name, optional")

                Label("Everything you enter stays on this device in this demo.", systemImage: "lock.fill")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
        }
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.Palette.gold)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.Palette.inkHighlight))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                Text(detail)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 2. Genres

struct GenreStepView: View {
    @Bindable var model: OnboardingViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        // One column at accessibility sizes so labels never truncate.
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 150), spacing: Theme.Spacing.md)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            OnboardingStepTitle(
                title: "What do you love to read?",
                subtitle: "Pick as many as you like. \(PipIdentity.name) uses these for suggestions — nothing else."
            )

            LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                ForEach(Genre.onboardingCases) { genre in
                    GenreChip(genre: genre, isSelected: model.selectedGenres.contains(genre)) {
                        model.toggle(genre)
                    }
                }
            }

            Text(selectionSummary)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private var selectionSummary: String {
        switch model.selectedGenres.count {
        case 0: "None selected yet"
        case 1: "1 genre selected"
        default: "\(model.selectedGenres.count) genres selected"
        }
    }
}

private struct GenreChip: View {
    let genre: Genre
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: isSelected ? "checkmark" : genre.symbol)
                    .font(.body.weight(.semibold))
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(genre.displayName)
                    .font(.bbHeadline)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.parchment)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(isSelected ? Theme.Palette.gold : Theme.Palette.inkRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Theme.Palette.hairline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Double-tap to remove." : "Double-tap to add.")
    }
}

// MARK: - 3. Reading goal

struct GoalStepView: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            OnboardingStepTitle(
                title: "Set a reading goal",
                subtitle: "Aim for what feels good. You can change it any time."
            )

            goalCounter

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Your reading pace")
                    .font(.bbTitle3)
                    .foregroundStyle(Theme.Palette.parchment)
                    .accessibilityAddTraits(.isHeader)
                ForEach(ReadingPace.allCases) { pace in
                    SelectableCard(isSelected: model.pace == pace, action: { model.pace = pace }) {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: pace.symbol)
                                .font(.title3)
                                .foregroundStyle(Theme.Palette.lavender)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pace.displayName)
                                    .font(.bbHeadline)
                                    .foregroundStyle(Theme.Palette.parchment)
                                Text(pace.detail)
                                    .font(.bbCallout)
                                    .foregroundStyle(Theme.Palette.parchmentMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private var goalCounter: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.lg) {
                CounterButton(systemImage: "minus", label: "Fewer books") { model.decrementGoal() }
                    .disabled(model.booksPerMonth <= OnboardingViewModel.booksPerMonthRange.lowerBound)
                VStack(spacing: 0) {
                    Text("\(model.booksPerMonth)")
                        .font(.system(size: 56, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.Palette.gold)
                        .contentTransition(.numericText())
                    Text(model.booksPerMonth == 1 ? "book a month" : "books a month")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.parchment)
                }
                .frame(minWidth: 140)
                CounterButton(systemImage: "plus", label: "More books") { model.incrementGoal() }
                    .disabled(model.booksPerMonth >= OnboardingViewModel.booksPerMonthRange.upperBound)
            }
            Text("About \(model.weeklyPagesEstimate) pages a week")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
        }
        .frame(maxWidth: .infinity)
        .bbCard()
        // Expose the whole counter as one adjustable control for VoiceOver (swipe up/down).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Books per month")
        .accessibilityValue("\(model.booksPerMonth), about \(model.weeklyPagesEstimate) pages a week")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.incrementGoal()
            case .decrement: model.decrementGoal()
            @unknown default: break
            }
        }
    }
}

private struct CounterButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(isEnabled ? Theme.Palette.ink : Theme.Palette.parchmentMuted)
                .frame(width: 52, height: 52)
                .background(Circle().fill(isEnabled ? Theme.Palette.lavender : Theme.Palette.inkHighlight))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - 4. Spoilers

struct SpoilerStepView: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            OnboardingStepTitle(
                title: "How do you feel about spoilers?",
                subtitle: "Summaries, quizzes and \(PipIdentity.name) will never show you more than this."
            )

            VStack(spacing: Theme.Spacing.md) {
                ForEach(SpoilerLevel.allCases) { level in
                    SelectableCard(isSelected: model.spoilerLevel == level, action: { model.spoilerLevel = level }) {
                        HStack(alignment: .top, spacing: Theme.Spacing.md) {
                            Image(systemName: level.symbol)
                                .font(.title3)
                                .foregroundStyle(Theme.Palette.lavender)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName)
                                    .font(.bbHeadline)
                                    .foregroundStyle(Theme.Palette.parchment)
                                Text(level.detail)
                                    .font(.bbCallout)
                                    .foregroundStyle(Theme.Palette.parchmentMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                PipAvatar(size: 40, mood: .happy, animated: false)
                Text("Next, you'll join **Midnight Margins**, a demo squad of five readers, so you can try everything right away.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .bbCard(fill: Theme.Palette.inkHighlight)
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("Welcome") {
    ScrollView { WelcomeStepView(model: OnboardingViewModel()).padding() }
        .background(InkBackground())
        .preferredColorScheme(.dark)
}

#Preview("Genres") {
    ScrollView { GenreStepView(model: OnboardingViewModel()).padding() }
        .background(InkBackground())
        .preferredColorScheme(.dark)
}

#Preview("Goal") {
    ScrollView { GoalStepView(model: OnboardingViewModel()).padding() }
        .background(InkBackground())
        .preferredColorScheme(.dark)
}

#Preview("Spoilers") {
    ScrollView { SpoilerStepView(model: OnboardingViewModel()).padding() }
        .background(InkBackground())
        .preferredColorScheme(.dark)
}
