// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

struct BookNote: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var bookID: UUID
    var chapter: Int
    var text: String
    var createdAt: Date = .now
}

/// A moment the reader wants to remember. Stored in the reader's own words —
/// the app never copies passages from the book itself.
struct SavedMoment: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var bookID: UUID
    var chapter: Int
    var title: String
    var reflection: String
    var createdAt: Date = .now
}
