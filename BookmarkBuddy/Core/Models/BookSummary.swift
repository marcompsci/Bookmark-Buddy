// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

enum SummaryMode: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case premise, whereIAm, fullRecap

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .premise: "Premise"
        case .whereIAm: "Where I am"
        case .fullRecap: "Full recap"
        }
    }
}

struct BookSummary: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var bookID: UUID
    var mode: SummaryMode
    var text: String
    /// The last chapter this summary covers, when relevant.
    var coveredThroughChapter: Int?
    /// Every summary in the MVP is produced by the mock service and must be labelled "Demo AI summary".
    var isDemoAI: Bool = true
    var generatedAt: Date = .now
}

/// The result of asking for a summary: either content or a spoiler-safe explanation of why it's locked.
enum SummaryResult: Hashable, Sendable {
    case available(BookSummary)
    case locked(reason: String)
}
