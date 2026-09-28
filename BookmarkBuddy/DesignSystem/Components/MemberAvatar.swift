// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Initials on a generated gradient. No photos are used in the MVP.
struct MemberAvatar: View {
    let name: String
    let seed: Int
    var size: CGFloat = 40
    var isCurrentUser = false

    var body: some View {
        let colors = Theme.avatarGradient(seed: seed)
        ZStack {
            Circle()
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(Initials.from(name))
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Palette.ink)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().strokeBorder(isCurrentUser ? Theme.Palette.gold : Theme.Palette.ink, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isCurrentUser ? "\(name), you" : name)
    }
}

/// Overlapping row of avatars, e.g. event attendees.
struct AvatarStack: View {
    let members: [SquadMember]
    var size: CGFloat = 32
    var maxVisible = 4

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(members.prefix(maxVisible)) { member in
                MemberAvatar(name: member.displayName, seed: member.avatarSeed, size: size, isCurrentUser: member.isCurrentUser)
            }
            if members.count > maxVisible {
                Text("+\(members.count - maxVisible)")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchment)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Theme.Palette.inkHighlight))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let names = members.map { $0.isCurrentUser ? "you" : $0.displayName }
        return names.isEmpty ? "No one yet" : ListFormatter.localizedString(byJoining: names)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            ForEach(DemoData.members) { member in
                MemberAvatar(name: member.displayName, seed: member.avatarSeed)
            }
        }
        AvatarStack(members: DemoData.members)
    }
    .padding()
    .background(InkBackground())
}
