// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

/// The reader's garden and game progress, saved on device so it survives relaunches.
///
/// - Plants: one per book. Strength grows with correct answers and slowly fades if a book
///   isn't refreshed (a gentle forgetting curve), so the garden visibly needs watering.
/// - Stats: XP, level, daily streak and today's combo.
@Observable
@MainActor
final class GardenStore {
    static let shared = GardenStore()

    struct Plant: Codable, Hashable, Sendable {
        var strength: Double
        var lastWatered: Date?
        var plantedAt: Date
        var correctInARow: Int = 0
        var timesWatered: Int = 0
    }

    struct Stats: Codable, Hashable, Sendable {
        var xp: Int = 0
        var dayStreak: Int = 0
        var bestStreak: Int = 0
        var lastActiveDay: Date?
        var combo: Int = 0
        var comboDay: Date?
        var answered: Int = 0
        var correct: Int = 0
    }

    /// What one answer earned — shown as a little celebration.
    struct Reward: Identifiable, Equatable, Sendable {
        let id = UUID()
        let correct: Bool
        let xp: Int
        let combo: Int
        let streak: Int
        let extendedStreak: Bool
        let newLevel: Int?
        let bookTitle: String?
    }

    private(set) var plants: [UUID: Plant] = [:]
    private(set) var stats = Stats()
    /// The latest reward, for the UI to celebrate. Cleared by the view once shown.
    var lastReward: Reward?

    private static let storageKey = "bb.garden.v1"

    // Forgetting curve: two grace days, then a little fade each day, never below a sprout.
    static let graceDays = 2.0
    static let fadePerDay = 0.03
    static let floor = 0.05

    private init() { load() }

    // MARK: Plants

    var plantedIDs: Set<UUID> { Set(plants.keys) }

    /// Adds a book to the garden as a seedling (no-op if it's already planted).
    func plant(bookID: UUID, strength: Double = 0.25) {
        guard plants[bookID] == nil else { return }
        plants[bookID] = Plant(strength: strength, lastWatered: nil, plantedAt: .now)
        save()
    }

    /// Strength right now, after fading for days without water.
    /// `seed` is used for books that aren't in the local garden yet (e.g. from the server).
    func strength(for bookID: UUID, seed: Double, now: Date = .now) -> Double {
        guard let plant = plants[bookID] else { return seed }
        return Self.faded(plant.strength, since: plant.lastWatered ?? plant.plantedAt, now: now)
    }

    func lastWatered(_ bookID: UUID) -> Date? { plants[bookID]?.lastWatered }

    static func faded(_ strength: Double, since date: Date, now: Date = .now) -> Double {
        let days = now.timeIntervalSince(date) / 86_400
        let fadeDays = max(0, days - graceDays)
        return max(floor, min(1, strength - fadeDays * fadePerDay))
    }

    // MARK: Answering

    /// Waters a plant and awards XP. Returns the new strength.
    @discardableResult
    func water(bookID: UUID, correct: Bool, seed: Double, bookTitle: String? = nil, now: Date = .now) -> Double {
        let current = strength(for: bookID, seed: seed, now: now)
        var plant = plants[bookID] ?? Plant(strength: seed, lastWatered: nil, plantedAt: now)
        plant.strength = min(1, max(Self.floor, current + (correct ? 0.12 : -0.04)))
        plant.lastWatered = now
        plant.timesWatered += 1
        plant.correctInARow = correct ? plant.correctInARow + 1 : 0
        plants[bookID] = plant

        lastReward = award(correct: correct, bookTitle: bookTitle, now: now)
        save()
        return plant.strength
    }

    private func award(correct: Bool, bookTitle: String?, now: Date) -> Reward {
        let calendar = Calendar.current
        let levelBefore = level

        // Daily streak: the first answer of a new day extends (or restarts) it.
        var extended = false
        if let last = stats.lastActiveDay, calendar.isDate(last, inSameDayAs: now) {
            // already counted today
        } else {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            if let last = stats.lastActiveDay, calendar.isDate(last, inSameDayAs: yesterday) {
                stats.dayStreak += 1
            } else {
                stats.dayStreak = 1
            }
            stats.bestStreak = max(stats.bestStreak, stats.dayStreak)
            stats.lastActiveDay = now
            extended = true
        }

        // Combo: correct answers in a row today.
        if let comboDay = stats.comboDay, calendar.isDate(comboDay, inSameDayAs: now) {} else { stats.combo = 0 }
        stats.comboDay = now
        stats.combo = correct ? stats.combo + 1 : 0

        var xp = correct ? 10 : 2
        if correct && stats.combo >= 2 { xp += min(20, (stats.combo - 1) * 5) }
        if extended { xp += 5 + min(15, stats.dayStreak) }   // show-up bonus grows with the streak

        stats.xp += xp
        stats.answered += 1
        if correct { stats.correct += 1 }

        let after = level
        return Reward(
            correct: correct,
            xp: xp,
            combo: stats.combo,
            streak: stats.dayStreak,
            extendedStreak: extended,
            newLevel: after > levelBefore ? after : nil,
            bookTitle: bookTitle
        )
    }

    /// The streak only counts if you answered today or yesterday.
    var liveStreak: Int {
        guard let last = stats.lastActiveDay else { return 0 }
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now) ?? .now
        return calendar.isDateInToday(last) || calendar.isDate(last, inSameDayAs: yesterday) ? stats.dayStreak : 0
    }

    var answeredToday: Bool {
        guard let last = stats.lastActiveDay else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: Levels

    /// Total XP needed to reach `level` (level 1 starts at 0): 0, 50, 150, 300, 500, 750…
    static func xpNeeded(for level: Int) -> Int { 25 * level * (level - 1) }

    var level: Int {
        var level = 1
        while stats.xp >= Self.xpNeeded(for: level + 1) { level += 1 }
        return level
    }

    /// 0…1 progress through the current level.
    var levelProgress: Double {
        let start = Self.xpNeeded(for: level)
        let end = Self.xpNeeded(for: level + 1)
        return Double(stats.xp - start) / Double(max(1, end - start))
    }

    var xpToNextLevel: Int { Self.xpNeeded(for: level + 1) - stats.xp }

    static func title(for level: Int) -> String {
        let titles = ["Seedling", "Sprout", "Sapling", "Gardener", "Botanist", "Grove Keeper", "Orchard Master", "Forest Sage"]
        if level <= titles.count { return titles[level - 1] }
        return "Forest Sage \(level - titles.count + 1)"
    }

    var levelTitle: String { Self.title(for: level) }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var plants: [UUID: Plant]
        var stats: Stats
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        plants = snapshot.plants
        stats = snapshot.stats
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Snapshot(plants: plants, stats: stats)) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    /// Called on sign-out and account deletion.
    func reset() {
        plants = [:]
        stats = Stats()
        lastReward = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}
