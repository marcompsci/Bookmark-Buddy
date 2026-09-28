// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Minimal on-device JSON persistence in Application Support.
/// Data is written with complete file protection and never leaves the device.
///
/// TODO(prod): Replace with SwiftData or a synced store once authentication and
/// server-side authorization exist. Account deletion must also purge server copies.
struct LocalStore: Sendable {
    let directory: URL

    init(folderName: String = "BookmarkBuddy") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.directory = base.appendingPathComponent(folderName, isDirectory: true)
    }

    private func url(for key: String) -> URL {
        directory.appendingPathComponent("\(key).json", isDirectory: false)
    }

    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let fileURL = url(for: key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, key: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        try data.write(to: url(for: key), options: [.atomic, .completeFileProtection])
    }

    func remove(key: String) {
        try? FileManager.default.removeItem(at: url(for: key))
    }

    func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}

/// Generic async loading state for view models.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

enum DemoServiceError: LocalizedError, Sendable {
    case simulatedFailure
    case notFound

    var errorDescription: String? {
        switch self {
        case .simulatedFailure: "Something went wrong loading demo data. Try again."
        case .notFound: "We couldn't find that item."
        }
    }
}

/// Simulated network latency for mock services. Zero in previews.
enum DemoLatency {
    static func pause(_ duration: Duration) async {
        guard duration > .zero else { return }
        try? await Task.sleep(for: duration)
    }
}
