// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Types its text in one character at a time with a blinking caret.
/// Shows the full text immediately with Reduce Motion, and always exposes the full text to VoiceOver.
struct DLTypewriterText: View {
    let text: String
    var font: Font = .system(.largeTitle, design: .serif).italic()
    /// Seconds per character.
    var speed: Double = 0.085
    var startDelay: Double = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0
    @State private var caretOn = true

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(String(text.prefix(shown)))
            if shown < text.count || caretOn {
                Rectangle()
                    .frame(width: 2, height: 28)
                    .opacity(caretOn ? 0.8 : 0)
                    .accessibilityHidden(true)
            }
        }
        .font(font)
        .foregroundStyle(Theme.Palette.parchment)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
        .task(id: text) { await type() }
    }

    private func type() async {
        if reduceMotion {
            shown = text.count
            caretOn = false
            return
        }
        shown = 0
        try? await Task.sleep(for: .seconds(startDelay))
        let characters = Array(text)
        for index in characters.indices {
            guard !Task.isCancelled else { return }
            shown = index + 1
            let pause = characters[index] == " " ? speed * 2.4 : speed
            try? await Task.sleep(for: .seconds(pause * Double.random(in: 0.8...1.4)))
        }
        // Blink a few times, then rest.
        for _ in 0..<6 {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .seconds(0.5))
            caretOn.toggle()
        }
        caretOn = false
    }
}

/// Small uppercase label with wide letter spacing.
struct DLEyebrow: View {
    let text: String
    var color: Color = Theme.Palette.parchmentMuted

    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .monospaced).weight(.medium))
            .tracking(2.5)
            .foregroundStyle(color)
    }
}

/// Pill button in the website's style.
struct DLPillButton: View {
    let title: String
    var filled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .tracking(1.5)
                .padding(.horizontal, Theme.Spacing.lg)
                .frame(minHeight: Theme.minTapTarget)
                .foregroundStyle(filled ? Theme.Palette.ink : Theme.Palette.parchment)
                .background(Capsule().fill(filled ? Theme.Palette.parchment : Color.clear))
                .overlay(Capsule().strokeBorder(Theme.Palette.parchment.opacity(filled ? 0 : 0.6), lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
