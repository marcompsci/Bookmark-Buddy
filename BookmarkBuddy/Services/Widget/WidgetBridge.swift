// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import WidgetKit

/// Keeps the home-screen widget in sync with Today. Cheap: one small JSON write + a reload.
@MainActor
enum WidgetBridge {
    static func publish(refresh: MemoryRefreshItem?, garden: [MemoryGardenEntry], thirsty: Int) {
        let store = GardenStore.shared
        let snapshot = WidgetSnapshot(
            question: refresh?.question.prompt,
            bookTitle: refresh?.book.title,
            answeredToday: store.answeredToday,
            streak: store.liveStreak,
            level: store.level,
            levelTitle: store.levelTitle,
            levelProgress: store.levelProgress,
            xp: store.stats.xp,
            plants: garden.sorted { $0.strength < $1.strength }.prefix(3).map {
                WidgetSnapshot.Plant(title: $0.book.title, strength: $0.strength)
            },
            thirsty: thirsty,
            updatedAt: .now
        )
        guard snapshot != WidgetSnapshot.load().map({ var s = $0; s.updatedAt = snapshot.updatedAt; return s }) else { return }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// After an answer from a notification: update streak/XP, keep the rest.
    static func publishStats() {
        let store = GardenStore.shared
        var snapshot = WidgetSnapshot.load() ?? .empty
        snapshot.answeredToday = store.answeredToday
        snapshot.streak = store.liveStreak
        snapshot.level = store.level
        snapshot.levelTitle = store.levelTitle
        snapshot.levelProgress = store.levelProgress
        snapshot.xp = store.stats.xp
        snapshot.updatedAt = .now
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
