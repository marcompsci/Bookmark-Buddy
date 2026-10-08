// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Cleans text people type before it is stored or shown to others.
/// Always render the result with plain `Text(verbatim:)`, never as markdown.
enum TextSanitizer {
    /// Trims whitespace, collapses runs of spaces, and removes control and
    /// bidirectional-override characters (used to disguise text direction).
    static func clean(_ input: String) -> String {
        let allowed = input.unicodeScalars.filter { scalar in
            if scalar == "\n" { return true }
            // Strip C0/C1 control characters.
            if CharacterSet.controlCharacters.contains(scalar) { return false }
            let v = scalar.value
            // Zero-width and invisible format marks (U+200B–U+200F).
            if v >= 0x200B && v <= 0x200F { return false }
            // BiDi override characters used to disguise text direction (U+202A–U+202E).
            if v >= 0x202A && v <= 0x202E { return false }
            // BiDi isolate controls (U+2066–U+206F).
            if v >= 0x2066 && v <= 0x206F { return false }
            // Private-use area (U+E000–U+F8FF).
            if v >= 0xE000 && v <= 0xF8FF { return false }
            // Specials block including object replacement character (U+FFF0–U+FFFF).
            if v >= 0xFFF0 && v <= 0xFFFF { return false }
            return true
        }
        return String(String.UnicodeScalarView(allowed))
            .replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `clean`, then cut to `limit` characters.
    static func clean(_ input: String, limit: Int) -> String {
        String(clean(input).prefix(limit))
    }
}
