// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import UIKit

/// Four-step onboarding: Welcome → Genres → Reading goal → Spoiler preference.
/// On finish it saves a local `UserProfile`, joins the demo squad "Midnight Margins",
/// and calls `onFinish` (which flips the `hasCompletedOnboarding` AppStorage flag).
struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = OnboardingViewModel()

    var body: some View {
        ZStack {
            InkBackground()

            VStack(spacing: 0) {
                OnboardingProgressHeader(step: model.step)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.md)

                ScrollView {
                    stepContent
                        .id(model.step)
                        .transition(stepTransition)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)

                footer
            }
        }
        .onChange(of: model.step) {
            // Move VoiceOver to the new step's content.
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
        .alert(
            "Couldn't finish setup",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome:
            WelcomeStepView(model: model)
        case .genres:
            GenreStepView(model: model)
        case .goal:
            GoalStepView(model: model)
        case .spoilers:
            SpoilerStepView(model: model)
        }
    }

    private var stepTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            )
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if model.step == .genres && !model.canContinue {
                Text("Pick at least one genre to continue.")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            HStack(spacing: Theme.Spacing.md) {
                if !model.isFirstStep {
                    SecondaryButton(title: "Back", systemImage: "chevron.left") {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { model.back() }
                    }
                    .disabled(model.isSaving)
                }
                PrimaryButton(
                    title: model.continueTitle,
                    systemImage: model.isLastStep ? "book.fill" : "arrow.right",
                    isLoading: model.isSaving
                ) {
                    advance()
                }
                .disabled(!model.canContinue)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .background(
            Theme.Palette.ink.opacity(0.92)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func advance() {
        if model.isLastStep {
            Task {
                if await model.finish(appState: appState) {
                    onFinish()
                }
            }
        } else {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { model.next() }
        }
    }
}

// MARK: - Progress header

private struct OnboardingProgressHeader: View {
    let step: OnboardingViewModel.Step

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.self) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? Theme.Palette.gold : Theme.Palette.parchment.opacity(0.18))
                    .frame(height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count), \(step.accessibilityTitle)")
    }
}

// MARK: - Shared step title

struct OnboardingStepTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(.bbDisplay)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Onboarding flow") {
    OnboardingView {}
        .withPreviewEnvironment(profile: nil)
}
