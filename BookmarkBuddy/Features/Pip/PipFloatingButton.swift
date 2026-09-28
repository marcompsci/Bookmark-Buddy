// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Draggable floating Pip button that lives above the tab content.
/// Single tap → opens Pip's chat sheet.
/// Long press → shows quick-action menu.
struct PipFloatingButton: View {
    @Environment(AppRouter.self) private var router
    @AppStorage(StorageKeys.pipPosition) private var positionData: Data = Data()
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height * 0.65)
    @State private var dragOffset: CGSize = .zero
    @State private var showQuickActions = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            pip(in: geo)
        }
        .onAppear { loadPosition() }
        .confirmationDialog("Quick actions", isPresented: $showQuickActions) {
            Button("What should I do next?") { openPip(prompt: "What should I do next?") }
            Button("Quiz me") { openPip(prompt: "Quiz me on The Glass Harbor.") }
            Button("Summarize my current book") { openPip(prompt: "Summarize my current book.") }
            Button("Help me create a trivia night") { openPip(prompt: "Help me create a trivia night.") }
            Button("Help me navigate") { openPip(prompt: "How do I use this app?") }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func pip(in geo: GeometryProxy) -> some View {
        let clampedX = min(max(position.x + dragOffset.width, 44), geo.size.width - 44)
        let clampedY = min(max(position.y + dragOffset.height, 44), geo.size.height - 80)

        return Button {
            router.present(.pip(bookID: nil))
        } label: {
            PipAvatar(size: 52, mood: .idle, animated: !reduceMotion)
                .shadow(color: Theme.Palette.lavender.opacity(0.6), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PipIdentity.accessibilityButtonLabel)
        .accessibilityHint("Long press for quick actions")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in showQuickActions = true }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    position.x = min(max(position.x + value.translation.width, 44), geo.size.width - 44)
                    position.y = min(max(position.y + value.translation.height, 44), geo.size.height - 80)
                    dragOffset = .zero
                    savePosition()
                }
        )
        .position(x: clampedX, y: clampedY)
    }

    private func openPip(prompt: String?) {
        router.present(.pip(bookID: nil))
    }

    private func loadPosition() {
        guard !positionData.isEmpty,
              let decoded = try? JSONDecoder().decode(CGPoint.self, from: positionData) else { return }
        position = decoded
    }

    private func savePosition() {
        positionData = (try? JSONEncoder().encode(position)) ?? Data()
    }
}

extension CGPoint: @retroactive Codable {
    public init(from decoder: any Decoder) throws {
        var c = try decoder.unkeyedContainer()
        self.init(x: try c.decode(CGFloat.self), y: try c.decode(CGFloat.self))
    }
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(x)
        try c.encode(y)
    }
}

#Preview {
    ZStack {
        InkBackground()
        PipFloatingButton()
    }
    .withPreviewEnvironment()
}
