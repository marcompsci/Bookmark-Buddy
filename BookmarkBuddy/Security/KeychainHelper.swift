// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Security

/// Thin, synchronous wrapper around the iOS Keychain (`SecItem` APIs).
/// Use this for any data too sensitive to keep in UserDefaults —
/// auth tokens, session IDs, or device secrets.
enum KeychainHelper {

    private static let service = "com.bookmarkbuddy.app"

    // MARK: - Write

    /// Stores `data` under `key`. Overwrites any existing entry. Returns `true` on success.
    @discardableResult
    static func save(_ data: Data, forKey key: String) -> Bool {
        let query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    static func saveString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }

    @discardableResult
    static func saveCodable<T: Encodable>(_ value: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return save(data, forKey: key)
    }

    // MARK: - Read

    static func load(forKey key: String) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func loadCodable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = load(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Delete

    static func delete(forKey key: String) {
        SecItemDelete(baseQuery(for: key) as CFDictionary)
    }

    /// Removes all Bookmark Buddy entries from the Keychain.
    static func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Private

    private static func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

// MARK: - Well-known keys

extension KeychainHelper {
    enum Keys {
        static let userProfileID = "userProfileID"
        static let sessionToken  = "sessionToken"   // reserved for future backend auth
        static let deviceSecret  = "deviceSecret"   // reserved for future backend auth
    }
}
