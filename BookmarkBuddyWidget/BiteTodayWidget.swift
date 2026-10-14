// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import WidgetKit

// MARK: - Bundle

@main
struct BookmarkBuddyWidgetBundle: WidgetBundle {
    var body: some Widget {
        BiteTodayWidget()
    }
}

// MARK: - Timeline

struct BiteEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct BiteProvider: TimelineProvider {
    func placeholder(in context: Context) -> BiteEntry {
        BiteEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BiteEntry) -> Void) {
        let snapshot = context.isPreview ? (WidgetSnapshot.load() ?? .placeholder) : (WidgetSnapshot.load() ?? .empty)
        completion(BiteEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BiteEntry>) -> Void) {
        var snapshot = WidgetSnapshot.load() ?? .empty
        // A new day: yesterday's "watered" state no longer counts.
        if !Calendar.current.isDateInToday(snapshot.updatedAt) { snapshot.answeredToday = false }
        let entry = BiteEntry(date: .now, snapshot: snapshot)
        // Refresh just after midnight so "answered today" resets; the app reloads us on every change.
        let midnight = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400)).addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - Widget

struct BiteTodayWidget: Widget {
    let kind = "BiteToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BiteProvider()) { entry in
            BiteWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetPalette.background }
                .widgetURL(WidgetSnapshot.openURL)
        }
        .configurationDisplayName("Bite's question")
        .description("Today's memory question, your streak and your garden.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

enum WidgetPalette {
    static let ink = Color(red: 0.067, green: 0.078, blue: 0.169)
    static let inkRaised = Color(red: 0.106, green: 0.122, blue: 0.239)
    static let parchment = Color(red: 0.953, green: 0.914, blue: 0.824)
    static let muted = Color(red: 0.953, green: 0.914, blue: 0.824).opacity(0.7)
    static let lavender = Color(red: 0.722, green: 0.663, blue: 0.890)
    static let gold = Color(red: 0.890, green: 0.722, blue: 0.361)
    static let forest = Color(red: 0.184, green: 0.420, blue: 0.298)
    static let forestBright = Color(red: 0.486, green: 0.761, blue: 0.604)
    static let water = Color(red: 0.45, green: 0.72, blue: 0.95)

    static var background: some View {
        LinearGradient(colors: [Color(red: 0.16, green: 0.36, blue: 0.27), ink], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct BiteWidgetView: View {
    let entry: BiteEntry
    @Environment(\.widgetFamily) private var family

    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        default: small
        }
    }

    private var headline: String {
        if s.question == nil { return "Pick a book and Bite will quiz you tomorrow." }
        if s.answeredToday { return "Watered for today 🌱" }
        return s.question ?? ""
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                BiteMark(size: 26, happy: s.answeredToday)
                Spacer(minLength: 0)
                streakBadge
            }
            Text(s.answeredToday ? "Done for today" : "Today's question")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.gold)
                .textCase(.uppercase)
            Text(headline)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(WidgetPalette.parchment)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            levelBar
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    BiteMark(size: 28, happy: s.answeredToday)
                    Text(s.answeredToday ? "Done for today" : "Today's question")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.gold)
                        .textCase(.uppercase)
                }
                Text(headline)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetPalette.parchment)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                if let book = s.bookTitle, !s.answeredToday {
                    Text(book)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                levelBar
            }
            VStack(alignment: .leading, spacing: 6) {
                streakBadge
                Text("GARDEN")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.muted)
                if s.plants.isEmpty {
                    Text("Nothing planted yet")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(WidgetPalette.muted)
                }
                ForEach(Array(s.plants.prefix(3).enumerated()), id: \.offset) { _, plant in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plant.title)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetPalette.parchment)
                            .lineLimit(1)
                        StrengthBar(value: plant.strength)
                    }
                }
                if s.thirsty > 0 {
                    Label("\(s.thirsty) thirsty", systemImage: "drop.fill")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.water)
                }
                Spacer(minLength: 0)
            }
            .frame(width: 112)
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: s.answeredToday ? "flame.fill" : "flame")
            Text("\(s.streak)")
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded))
        .foregroundStyle(s.answeredToday ? WidgetPalette.gold : WidgetPalette.muted)
    }

    private var levelBar: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Lv \(s.level) · \(s.levelTitle)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.muted)
            StrengthBar(value: s.levelProgress, colors: [WidgetPalette.forestBright, WidgetPalette.gold])
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        Gauge(value: min(1, max(0, s.levelProgress))) {
            Image(systemName: "leaf.fill")
        } currentValueLabel: {
            VStack(spacing: 0) {
                Image(systemName: s.answeredToday ? "flame.fill" : "flame").font(.system(size: 10))
                Text("\(s.streak)").font(.system(size: 15, weight: .bold, design: .rounded))
            }
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("🔥 \(s.streak) · Lv \(s.level)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Text(headline)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
        }
        .widgetAccentable()
    }

    private var inline: some View {
        Text(s.answeredToday ? "🔥 \(s.streak) · watered today" : "🔥 \(s.streak) · Bite has a question")
    }
}

/// A tiny Bite: lavender orb with a face and a gold bookmark tail.
struct BiteMark: View {
    let size: CGFloat
    var happy = true

    var body: some View {
        ZStack {
            Rectangle()
                .fill(WidgetPalette.gold)
                .frame(width: size * 0.2, height: size * 0.4)
                .rotationEffect(.degrees(18), anchor: .top)
                .offset(x: size * 0.2, y: size * 0.38)
            Circle()
                .fill(RadialGradient(colors: [Color(red: 0.88, green: 0.85, blue: 0.99), WidgetPalette.lavender, Color(red: 0.5, green: 0.43, blue: 0.78)],
                                     center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.65))
            HStack(spacing: size * 0.16) {
                Capsule().fill(WidgetPalette.ink).frame(width: size * 0.12, height: size * 0.17)
                Capsule().fill(WidgetPalette.ink).frame(width: size * 0.12, height: size * 0.17)
            }
            .offset(y: -size * 0.06)
            Capsule()
                .fill(WidgetPalette.ink)
                .frame(width: size * (happy ? 0.24 : 0.14), height: size * 0.06)
                .offset(y: size * 0.16)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct StrengthBar: View {
    let value: Double
    var colors: [Color] = [WidgetPalette.forestBright, WidgetPalette.forestBright]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(WidgetPalette.parchment.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: value < 0.3 ? [WidgetPalette.lavender, WidgetPalette.lavender] : colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(4, proxy.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: 5)
    }
}

#Preview(as: .systemMedium) {
    BiteTodayWidget()
} timeline: {
    BiteEntry(date: .now, snapshot: .placeholder)
}
