// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

struct BookRecommendation: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var bookID: UUID
    var recommenderID: UUID
    var recommenderName: String
    var note: String?
    var createdAt: Date
}

/// A public-facing user profile visible in the Explore page.
/// In production this would be fetched from the server with proper auth.
struct ExploreUser: Identifiable, Hashable, Sendable {
    var id: UUID
    var displayName: String
    var avatarSeed: Int
    var bio: String
    var favoriteGenres: [Genre]
    /// IDs of books on their public shelf.
    var shelfBookIDs: [UUID]
    var isFollowing: Bool = false

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }
}
