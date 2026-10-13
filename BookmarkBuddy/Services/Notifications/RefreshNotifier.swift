// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation
import UserNotifications

/// Daily memory-refresh notifications with the question in the notification itself
/// and one button per answer, so a reader can answer without opening the app.
///
/// Repeating notifications can't change their text, so this schedules the next week of
/// one-shot notifications (one question per day) and reschedules whenever the app opens.
@Observable
@MainActor
final class RefreshNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = RefreshNotifier()

    /// Bumped when someone taps a refresh notification; Today opens the question.
    private(set) var openRefreshRequest = 0

    @ObservationIgnored private var services: AppServices?

    private static let requestPrefix = "bb.refresh."
    private static let categoryPrefix = "bb.refresh.cat."
    private static let legacyRequestID = "bb.memoryRefresh"
    private static let resultRequestID = "bb.refresh.result"
    private static let daysAhead = 7

    /// Call once at launch, before the app finishes launching, so answers tapped
    /// while the app was closed are delivered here.
    func configure(services: AppServices) {
        self.services = services
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: Settings

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKeys.refreshReminderEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKeys.refreshReminderEnabled) }
    }

    var hour: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: StorageKeys.refreshReminderHour) as? Int
            return stored ?? 19
        }
        set { UserDefaults.standard.set(newValue, forKey: StorageKeys.refreshReminderHour) }
    }

    /// Asks for permission. Returns false if the person declines (or declined before).
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    // MARK: Scheduling

    /// Replaces any pending refresh notifications with the next week of questions.
    /// - Parameters:
    ///   - startTomorrow: skip today even if the reminder time hasn't passed yet.
    ///   - firstBookID: the book the first notification should be about.
    func reschedule(startTomorrow: Bool = false, firstBookID: UUID? = nil) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter {
            ($0.hasPrefix(Self.requestPrefix) && $0 != Self.resultRequestID) || $0 == Self.legacyRequestID
        }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        guard isEnabled, let services else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        // Gather one question per day, starting with the pinned book if there is one.
        var items: [MemoryRefreshItem] = []
        let pinned = firstBookID ?? FirstRefreshPromise.pendingBookID
        if let pinned, let item = try? await services.quizzes.refreshItem(for: pinned) {
            items.append(item)
        }
        while items.count < Self.daysAhead {
            guard let item = try? await services.quizzes.memoryRefreshItem() else { break }
            items.append(item)
        }

        // Keep the first-run promise: nothing fires before the promised day.
        let notBefore = FirstRefreshPromise.isUpcoming ? FirstRefreshPromise.date : nil
        let dates = Self.upcomingDates(hour: hour, count: Self.daysAhead, startTomorrow: startTomorrow, notBefore: notBefore)
        var categories: Set<UNNotificationCategory> = []

        for (offset, fireDate) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.sound = .default
            let identifier = Self.requestPrefix + "\(offset)"

            if offset < items.count {
                let item = items[offset]
                let options = Array(item.question.options.prefix(4))
                let categoryID = Self.categoryPrefix + "\(offset)"
                let actions = options.enumerated().map { index, option in
                    UNNotificationAction(identifier: "answer.\(index)", title: Self.trim(option), options: [])
                }
                categories.insert(UNNotificationCategory(identifier: categoryID, actions: actions, intentIdentifiers: []))

                content.title = "\(PipIdentity.name) · \(item.book.title)"
                content.body = item.question.prompt + "\nPress and hold to answer."
                content.categoryIdentifier = categoryID
                content.userInfo = [
                    "bookID": item.book.id.uuidString,
                    "bookTitle": item.book.title,
                    "correctIndex": item.question.correctIndex,
                    "options": options,
                    "explanation": item.question.explanation,
                ]
            } else {
                // No question available (nothing finished yet) — a gentle nudge instead.
                content.title = "\(PipIdentity.name) has a question for you"
                content.body = "One quick question keeps your books from fading. Tap to answer."
            }

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
        center.setNotificationCategories(categories)
    }

    func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.requestPrefix) || $0 == Self.legacyRequestID }
        )
    }

    /// The next `count` reminder times at `hour`:00.
    static func upcomingDates(hour: Int, count: Int, startTomorrow: Bool, notBefore: Date? = nil, now: Date = .now) -> [Date] {
        let calendar = Calendar.current
        guard var first = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) else { return [] }
        if startTomorrow || first <= now {
            first = calendar.date(byAdding: .day, value: 1, to: first) ?? first
        }
        if let notBefore,
           let promisedDay = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: notBefore),
           promisedDay > first {
            first = promisedDay
        }
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }

    private static func trim(_ option: String) -> String {
        option.count > 40 ? String(option.prefix(39)) + "…" : option
    }

    // MARK: UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        let reply = RefreshReply(
            actionIdentifier: response.actionIdentifier,
            bookID: (info["bookID"] as? String).flatMap(UUID.init(uuidString:)),
            bookTitle: info["bookTitle"] as? String ?? "your book",
            correctIndex: info["correctIndex"] as? Int,
            options: info["options"] as? [String] ?? [],
            explanation: info["explanation"] as? String ?? ""
        )
        await handle(reply)
    }

    private func handle(_ reply: RefreshReply) async {
        if reply.actionIdentifier.hasPrefix("answer."),
           let index = Int(reply.actionIdentifier.dropFirst("answer.".count)),
           let bookID = reply.bookID,
           let correctIndex = reply.correctIndex {
            let correct = index == correctIndex
            await services?.quizzes.recordRefresh(bookID: bookID, wasCorrect: correct)
            FirstRefreshPromise.markAnswered(bookID: bookID)
            Analytics.log(.refreshAnswered, ["source": "notification", "correct": correct ? "yes" : "no"])
            await postResult(correct: correct, reply: reply)
        } else if reply.actionIdentifier == UNNotificationDefaultActionIdentifier {
            Analytics.log(.notificationOpened)
            openRefreshRequest += 1
        }
    }

    /// Immediate follow-up so the reader knows how they did without opening the app.
    private func postResult(correct: Bool, reply: RefreshReply) async {
        let content = UNMutableNotificationContent()
        if correct {
            content.title = "Nice! 🌱"
            content.body = "\(PipIdentity.name) watered “\(reply.bookTitle)” in your Memory Garden."
        } else {
            let answer = reply.correctIndex.flatMap { reply.options.indices.contains($0) ? reply.options[$0] : nil } ?? ""
            content.title = "Not quite — it was “\(answer)”"
            content.body = reply.explanation.isEmpty ? "Tomorrow's question will help it stick." : reply.explanation
        }
        let request = UNNotificationRequest(identifier: Self.resultRequestID, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

/// Plain values pulled out of a notification response (userInfo itself isn't Sendable).
private struct RefreshReply: Sendable {
    let actionIdentifier: String
    let bookID: UUID?
    let bookTitle: String
    let correctIndex: Int?
    let options: [String]
    let explanation: String
}

/// "Tomorrow I'll ask you about this book" — the promise made on first run.
enum FirstRefreshPromise {
    static func make(bookID: UUID, title: String, date: Date) {
        let defaults = UserDefaults.standard
        defaults.set(bookID.uuidString, forKey: StorageKeys.firstRefreshBookID)
        defaults.set(title, forKey: StorageKeys.firstRefreshBookTitle)
        defaults.set(date, forKey: StorageKeys.firstRefreshDate)
    }

    /// The promised book, until it has been answered.
    static var pendingBookID: UUID? {
        UserDefaults.standard.string(forKey: StorageKeys.firstRefreshBookID).flatMap(UUID.init(uuidString:))
    }

    static var title: String? { UserDefaults.standard.string(forKey: StorageKeys.firstRefreshBookTitle) }
    static var date: Date? { UserDefaults.standard.object(forKey: StorageKeys.firstRefreshDate) as? Date }

    /// True while the promised question is still in the future.
    static var isUpcoming: Bool {
        guard pendingBookID != nil, let date else { return false }
        return date > .now
    }

    /// True once the promised time has arrived and the question hasn't been answered.
    static var isDue: Bool {
        guard pendingBookID != nil, let date else { return false }
        return date <= .now
    }

    static func markAnswered(bookID: UUID) {
        guard pendingBookID == bookID else { return }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StorageKeys.firstRefreshBookID)
        defaults.removeObject(forKey: StorageKeys.firstRefreshBookTitle)
        defaults.removeObject(forKey: StorageKeys.firstRefreshDate)
    }
}
