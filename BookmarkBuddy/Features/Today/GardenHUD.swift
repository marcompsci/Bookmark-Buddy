// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Level, XP bar, daily streak, and Bite's read on how the garden is doing.
struct GardenHUD: View {
    let gardenCount: Int
    let averageStrength: Double
    let thirstyCount: Int

    private var store: GardenStore { GardenStore.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                levelBadge
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(store.levelTitle)
                            .font(.bbHeadline)
                            .foregroundStyle(Theme.Palette.parchment)
                        Spacer()
                        Text("\(store.xpToNextLevel) XP to Lv \(store.level + 1)")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                    XPBar(progress: store.levelProgress)
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                StatPill(
                    value: "\(store.liveStreak)",
                    label: store.liveStreak == 1 ? "day streak" : "day streak",
                    systemImage: store.answeredToday ? "flame.fill" : "flame",
                    tint: store.answeredToday ? Theme.Palette.gold : Theme.Palette.parchmentMuted
                )
                StatPill(value: "\(store.stats.xp)", label: "XP", systemImage: "sparkles", tint: Theme.Palette.lavender)
                if store.stats.combo >= 2 && store.answeredToday {
                    StatPill(value: "×\(store.stats.combo)", label: "combo", systemImage: "bolt.fill", tint: Theme.Palette.forestBright)
                }
            }

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                PipAvatar(size: 36, mood: biteMood, animated: false)
                Text(biteLine)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .bbCard()
        .accessibilityElement(children: .combine)
    }

    private var levelBadge: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Theme.Palette.forestBright, Theme.Palette.forest], startPoint: .top, endPoint: .bottom))
            Circle().strokeBorder(Theme.Palette.gold.opacity(0.8), lineWidth: 2)
            VStack(spacing: -2) {
                Text("LV").font(.system(size: 9, weight: .heavy, design: .rounded))
                Text("\(store.level)").font(.system(size: 20, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Theme.Palette.parchment)
        }
        .frame(width: 52, height: 52)
        .accessibilityLabel("Level \(store.level), \(store.levelTitle)")
    }

    private var biteMood: PipAvatar.Mood {
        if gardenCount == 0 { return .happy }
        if averageStrength < 0.35 || thirstyCount >= 2 { return .thinking }
        if store.liveStreak >= 3 || averageStrength >= 0.75 { return .cheering }
        return .happy
    }

    private var biteLine: String {
        let streak = store.liveStreak
        if gardenCount == 0 {
            return "Plant your first book and I'll help it grow. One answer a day is all it takes."
        }
        if !store.answeredToday && streak >= 2 {
            return "🔥 \(streak)-day streak on the line! Answer one question to keep it alive."
        }
        if thirstyCount >= 2 {
            return "\(thirstyCount) plants are thirsty 💧 Tap one to water it with a quick question."
        }
        if averageStrength < 0.35 {
            return "Your garden is wilting a little. A couple of answers will perk it right up."
        }
        if store.answeredToday && streak >= 3 {
            return "Watered for today — \(streak) days straight! Your books are sticking. 🌱"
        }
        if store.answeredToday {
            return "Nice! Today's watering is done. Come back tomorrow to grow your streak."
        }
        return "Your garden looks healthy. One question today keeps it that way."
    }
}

/// Thin animated XP progress bar.
struct XPBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.inkHighlight)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.Palette.forestBright, Theme.Palette.gold], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, proxy.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        .accessibilityHidden(true)
    }
}

/// "+15 XP · Combo ×2" — and a bigger celebration on level-up.
struct RewardBanner: View {
    let reward: GardenStore.Reward
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let level = reward.newLevel {
                HStack(spacing: Theme.Spacing.md) {
                    PipAvatar(size: 48, mood: .cheering, animated: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Level up! 🎉")
                            .font(.bbTitle3)
                            .foregroundStyle(Theme.Palette.gold)
                        Text("You're now Lv \(level) · \(GardenStore.title(for: level))")
                            .font(.bbHeadline)
                            .foregroundStyle(Theme.Palette.parchment)
                    }
                    Spacer(minLength: 0)
                }
            }
            HStack(spacing: Theme.Spacing.sm) {
                Label("+\(reward.xp) XP", systemImage: "sparkles")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.lavender)
                if reward.combo >= 2 {
                    Label("Combo ×\(reward.combo)", systemImage: "bolt.fill")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.forestBright)
                }
                if reward.extendedStreak {
                    Label("\(reward.streak)-day streak", systemImage: "flame.fill")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.gold)
                }
                Spacer(minLength: 0)
            }
            .labelStyle(.titleAndIcon)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.inkHighlight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(reward.newLevel != nil ? Theme.Palette.gold : Theme.Palette.hairline, lineWidth: reward.newLevel != nil ? 2 : 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .sensoryFeedback(reward.newLevel != nil ? .success : .impact(weight: .light), trigger: reward.id)
        .task(id: reward.id) {
            try? await Task.sleep(for: .seconds(reward.newLevel != nil ? 5 : 3))
            onDismiss()
        }
        .accessibilityElement(children: .combine)
    }
}
