// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import UIKit

struct QuizFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: QuizViewModel

    init(bookID: UUID?, mode: QuizMode) {
        _model = State(initialValue: QuizViewModel(bookID: bookID, mode: mode))
    }

    private var animation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.3) }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    phaseContent
                }
                .padding(Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .navigationTitle(model.quiz?.title ?? model.mode.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load(services: services, spoilerLevel: appState.profile?.spoilerLevel ?? .premiseOnly)
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch model.phase {
        case .loading:
            LoadingCard(label: "Loading quiz", lines: 4)
        case .unavailable(let message):
            EmptyStateView(systemImage: "lock", title: "Quiz unavailable", message: message, actionTitle: "Go back") {
                dismiss()
            }
            .bbCard()
        case .intro:
            intro
        case .question:
            if let question = model.currentQuestion {
                questionView(question)
            }
        case .finished(let result):
            QuizResultView(
                result: result,
                onChallenge: { router.requestConfirmation(.challengeSquad(result)) },
                onReplay: { withAnimation(animation) { model.start() } },
                onDone: { dismiss() }
            )
        }
    }

    // MARK: Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Spacer()
                PipAvatar(size: 88, mood: .happy)
                Spacer()
            }
            Text(model.quiz?.title ?? model.mode.displayName)
                .font(.bbDisplay)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(introText)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.Spacing.sm) {
                StatPill(value: "\(model.questionCount)", label: model.questionCount == 1 ? "question" : "questions", systemImage: "questionmark.circle")
                StatPill(value: "\(MockQuizService.pointsPerCorrectAnswer)", label: "pts each", systemImage: "star.fill", tint: Theme.Palette.lavender)
            }
            if model.hiddenForSpoilers > 0 {
                Label("\(model.hiddenForSpoilers) question(s) skipped to avoid spoilers.", systemImage: "eye.slash")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            if model.book?.isDemoContent == true || model.mode == .quickRecall {
                Text("Questions use fictional demo content.")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
            } else if model.mode == .titleAndAuthor {
                Text("Uses titles and authors from your library only. No book content.")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
            }
            PrimaryButton(title: "Start", systemImage: "play.fill") {
                withAnimation(animation) { model.start() }
            }
        }
    }

    private var introText: String {
        switch model.mode {
        case .titleAndAuthor:
            "\(PipIdentity.name) here! Let's see how well you know who wrote what on your shelf."
        default:
            "\(PipIdentity.name) here! Quick questions, no pressure. Every right answer helps this book stay fresh."
        }
    }

    // MARK: Question

    private func questionView(_ question: QuizQuestion) -> some View {
        let index = model.currentIndex ?? 0
        return VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Question \(index + 1) of \(model.questionCount)")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.gold)
                    Spacer()
                    Text("\(model.correctSoFar) correct")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
                ProgressView(value: model.progressFraction)
                    .tint(Theme.Palette.gold)
                    .accessibilityLabel("Quiz progress")
                    .accessibilityValue("Question \(index + 1) of \(model.questionCount)")
            }

            Text(question.prompt)
                .font(.bbTitle)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                    AnswerOptionButton(text: option, state: optionState(optionIndex, question: question)) {
                        choose(optionIndex, question: question)
                    }
                    .disabled(model.selectedAnswer != nil)
                }
            }

            if let selected = model.selectedAnswer {
                feedback(correct: question.isCorrect(selected), question: question)
                PrimaryButton(
                    title: model.isLastQuestion ? "See my score" : "Next question",
                    systemImage: model.isLastQuestion ? "flag.checkered" : "arrow.right",
                    isLoading: model.isScoring
                ) {
                    Task {
                        await model.next(services: services, appState: appState)
                        router.dataChanged()
                    }
                }
            }
        }
        .id(index)
        .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
    }

    private func choose(_ option: Int, question: QuizQuestion) {
        withAnimation(animation) { model.select(option) }
        let announcement = question.isCorrect(option)
            ? "Correct."
            : "Not quite. The answer is \(question.options[safe: question.correctIndex] ?? "")."
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func optionState(_ index: Int, question: QuizQuestion) -> AnswerOptionButton.OptionState {
        guard let selected = model.selectedAnswer else { return .idle }
        if index == question.correctIndex { return .correct }
        if index == selected { return .incorrect }
        return .dimmed
    }

    private func feedback(correct: Bool, question: QuizQuestion) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            PipAvatar(size: 40, mood: correct ? .cheering : .thinking, animated: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(correct ? "Yes! Nicely remembered." : "Not quite, but now you'll remember.")
                    .font(.bbHeadline)
                    .foregroundStyle(correct ? Theme.Palette.forestBright : Theme.Palette.gold)
                Text(question.explanation)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .bbCard(fill: Theme.Palette.inkHighlight)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Result

struct QuizResultView: View {
    let result: QuizResult
    let onChallenge: () -> Void
    let onReplay: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringProgress: Double = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .stroke(Theme.Palette.parchment.opacity(0.12), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Theme.Palette.gold, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(result.correctCount)/\(result.totalCount)")
                        .font(.system(size: 44, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.Palette.parchment)
                    Text("correct")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
            }
            .frame(width: 170, height: 170)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Score: \(result.correctCount) out of \(result.totalCount)")
            .onAppear {
                if reduceMotion {
                    ringProgress = result.accuracy
                } else {
                    withAnimation(.easeOut(duration: 0.8)) { ringProgress = result.accuracy }
                }
            }

            StatPill(value: "+\(result.pointsEarned)", label: "squad points", systemImage: "star.fill")

            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                PipAvatar(size: 48, mood: result.accuracy >= 0.6 ? .cheering : .happy)
                Text(QuizViewModel.pipComment(for: result))
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .bbCard(fill: Theme.Palette.inkHighlight)
            .accessibilityElement(children: .combine)

            VStack(spacing: Theme.Spacing.sm) {
                PrimaryButton(title: "Challenge the squad", systemImage: "flag.checkered", action: onChallenge)
                    .accessibilityHint("Shows a confirmation before anything is posted")
                SecondaryButton(title: "Play again", systemImage: "arrow.counterclockwise", action: onReplay)
                SecondaryButton(title: "Done", action: onDone)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Glass Harbor quiz") {
    NavigationStack {
        QuizFlowView(bookID: DemoData.IDs.glassHarbor, mode: .quickRecall)
    }
    .withPreviewEnvironment()
}

#Preview("Title & Author") {
    NavigationStack {
        QuizFlowView(bookID: nil, mode: .titleAndAuthor)
    }
    .withPreviewEnvironment()
}
