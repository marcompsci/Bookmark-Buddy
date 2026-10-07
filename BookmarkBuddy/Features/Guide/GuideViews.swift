// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Anchor

extension View {
    /// Lets Guide Me highlight this view when the current step targets it.
    func guideAnchor(_ target: GuideTarget?) -> some View {
        modifier(GuideAnchorModifier(target: target))
    }

    /// Shows the Guide Me coach card along the bottom of this view while a guide runs.
    /// `inSheet` hosts read steps inside a modal; the root host hides while a sheet is up.
    func guideCoachHost(inSheet: Bool = false) -> some View {
        modifier(GuideCoachHostModifier(inSheet: inSheet))
    }
}

private struct GuideAnchorModifier: ViewModifier {
    let target: GuideTarget?
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    private var isHighlighted: Bool {
        guard let target else { return false }
        return router.guide.currentStep?.target == target
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(Theme.Palette.gold, lineWidth: 3)
                        .padding(-6)
                        .shadow(color: Theme.Palette.gold.opacity(0.7), radius: pulsing ? 14 : 4)
                        .opacity(pulsing ? 1 : 0.65)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .onAppear {
                            guard !reduceMotion else { pulsing = true; return }
                            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                pulsing = true
                            }
                        }
                        .onDisappear { pulsing = false }
                }
            }
    }
}

// MARK: - Coach card host

private struct GuideCoachHostModifier: ViewModifier {
    let inSheet: Bool
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldShow: Bool {
        guard let step = router.guide.currentStep else { return false }
        if inSheet { return step.target.isInEventPlanner }
        return router.sheet == nil && !step.target.isInEventPlanner
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if shouldShow, let step = router.guide.currentStep {
                    GuideCoachCard(step: step)
                        .padding(.horizontal, Theme.Spacing.lg)
                        // Root host sits above the tab bar; sheet host above the home indicator.
                        .padding(.bottom, inSheet ? Theme.Spacing.lg : 64)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.35), value: router.guide.currentStep?.id)
    }
}

/// The floating card that explains the current step.
struct GuideCoachCard: View {
    let step: GuideStep
    @Environment(AppRouter.self) private var router

    private var guide: GuideCoordinator { router.guide }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                PipAvatar(size: 28)
                    .accessibilityHidden(true)
                Text("Step \(guide.stepIndex + 1) of \(guide.stepCount)")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
                Spacer()
                Button("End guide") { guide.end() }
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .frame(minHeight: Theme.minTapTarget)
            }

            Text(step.title)
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.parchment)
            Text(step.message)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Theme.Spacing.sm) {
                if let shortcut = shortcutTitle {
                    SecondaryButton(title: shortcut, fullWidth: false) { performShortcut() }
                }
                Spacer(minLength: 0)
                PrimaryButton(title: guide.isLastStep ? "Done" : "Next", fullWidth: false) {
                    guide.advance()
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Palette.inkRaised)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Palette.gold.opacity(0.5), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Guide: \(step.title)")
    }

    /// Steps that point outside the current screen get a one-tap shortcut.
    private var shortcutTitle: String? {
        switch step.target {
        case .squadTab: "Take me there"
        case .createEventButton: "Open planner"
        default: nil
        }
    }

    private func performShortcut() {
        switch step.target {
        case .squadTab:
            router.select(.squad, popToRoot: true)
        case .createEventButton:
            router.present(.createEvent(.triviaNight))
        default:
            break
        }
    }
}

#Preview {
    ZStack {
        InkBackground()
        GuideCoachCard(step: DemoData.triviaNightWalkthrough.steps[1])
            .padding()
    }
    .withPreviewEnvironment()
}
