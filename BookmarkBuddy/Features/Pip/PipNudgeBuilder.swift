// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Builds Pip's short daily nudge from local data only. Pure and deterministic, so it's easy to test.
/// Respects "Allow Pip to use my reading progress": when that's off, the nudge stays generic.
enum PipNudgeBuilder {
    struct Nudge: Equatable {
        var text: String
        var action: PipAction?
    }

    static func nudge(
        profile: UserProfile?,
        current: BookWithProgress?,
        event: ReadingEvent?,
        refresh: MemoryRefreshItem?,
        permissions: PipPermissionSettings,
        now: Date = .now
    ) -> Nudge {
        guard permissions.allowReadingProgress else {
            return Nudge(text: "Ten pages tonight is a win. Small reading streaks add up faster than you'd think.", action: nil)
        }

        // 1. An event is coming up soon and you haven't RSVP'd.
        if let event, let profile, !event.isAttending(profile.id),
           event.startsAt.timeIntervalSince(now) < 4 * 86_400 {
            let day = event.startsAt.formatted(.dateTime.weekday(.wide))
            return Nudge(
                text: "\(event.title) is \(day). Tap RSVP so your squad knows you're in.",
                action: .showUpcomingEvent
            )
        }

        // 2. A finished book is fading from memory.
        if let refresh {
            return Nudge(
                text: "It's been a while since \(refresh.book.title). One quick question keeps it fresh.",
                action: nil
            )
        }

        // 3. Keep momentum on the current read.
        if let current, let progress = current.progress {
            let remaining = max(0, current.book.chapterCount - progress.currentChapter)
            let streak = profile?.currentStreakDays ?? 0
            let streakText = streak > 1 ? " and keeps your \(streak)-day streak going" : ""
            return Nudge(
                text: "You're on Chapter \(progress.currentChapter) of \(current.book.title), with \(remaining) chapters to go. One chapter tonight\(streakText).",
                action: .openBook(current.book.id)
            )
        }

        return Nudge(text: "Pick something from your Want to Read shelf and start with just one chapter.", action: .openTab(.library))
    }
}
