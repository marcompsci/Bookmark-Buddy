// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// The single approval gate for consequential actions (invites, posts, deletes, settings).
/// Present with `.sheet(item:)` bound to `AppRouter.pendingConfirmation` or local state.
struct ConfirmationSheet: View {
    let action: PendingAction
    let onConfirm: () async -> Void
    let onCancel: () -> Void

    @State private var isWorking = false
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: action.systemImage)
                    .font(.title2)
                    .foregroundStyle(action.isDestructive ? Theme.Palette.danger : Theme.Palette.gold)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Theme.Palette.inkHighlight))
                    .accessibilityHidden(true)
                Text(action.title)
                    .font(.bbTitle)
                    .foregroundStyle(Theme.Palette.parchment)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)
            }

            Text(action.message)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)

            Label(action.demoFootnote, systemImage: "lock.shield")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)

            Spacer(minLength: 0)

            VStack(spacing: Theme.Spacing.sm) {
                if action.isDestructive {
                    Button {
                        confirm()
                    } label: {
                        Text(action.confirmTitle)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .disabled(isWorking)
                } else {
                    PrimaryButton(title: action.confirmTitle, systemImage: action.systemImage, isLoading: isWorking) {
                        confirm()
                    }
                }
                SecondaryButton(title: "Cancel") {
                    onCancel()
                }
                .disabled(isWorking)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Palette.inkRaised.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isWorking)
        .onAppear { titleFocused = true }
    }

    private func confirm() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            await onConfirm()
            isWorking = false
        }
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bbHeadline)
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.Palette.danger.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4))
            )
            .contentShape(Capsule(style: .continuous))
    }
}

extension View {
    /// Attaches the shared confirmation gate to a binding.
    func confirmationGate(
        _ pending: Binding<PendingAction?>,
        perform: @escaping (PendingAction) async -> Void
    ) -> some View {
        sheet(item: pending) { action in
            ConfirmationSheet(
                action: action,
                onConfirm: {
                    await perform(action)
                    pending.wrappedValue = nil
                },
                onCancel: { pending.wrappedValue = nil }
            )
        }
    }
}

#Preview("Create event") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            if let event = DemoData.events.first {
                ConfirmationSheet(action: .createEvent(event), onConfirm: {}, onCancel: {})
            }
        }
}

#Preview("Destructive") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ConfirmationSheet(action: .resetPipMemory, onConfirm: {}, onCancel: {})
        }
}
