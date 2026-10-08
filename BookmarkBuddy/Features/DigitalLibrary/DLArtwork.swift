// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Spine

/// A book spine drawn entirely from data: curved-spine shading, vertical title,
/// author in the accent color, publisher at the foot, and the book's decoration.
struct DLSpineView: View {
    let book: DLBook
    /// 1 = the website's point sizes. The shelf uses ~0.62 to fit a phone.
    var scale: CGFloat = 0.62

    private var spine: DLSpine { book.spine }
    private var width: CGFloat { spine.widthPt * scale }
    private var height: CGFloat { spine.heightPt * scale }

    var body: some View {
        ZStack {
            spine.backgroundColor
            // Curved spine: darker edges, a soft highlight just left of center.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.35), location: 0),
                    .init(color: .white.opacity(0.14), location: 0.28),
                    .init(color: .clear, location: 0.55),
                    .init(color: .black.opacity(0.32), location: 1)
                ],
                startPoint: .leading, endPoint: .trailing
            )
            decoration
            VStack(spacing: 6 * scale) {
                Text(displayTitle)
                    .font(spine.titleFont(size: titleSize))
                    .foregroundStyle(spine.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(width: height * 0.6)
                    .rotationEffect(.degrees(90))
                    .frame(width: width, height: height * 0.62)
                Spacer(minLength: 0)
                Text(spine.author)
                    .font(.system(size: max(6, 9 * scale * 1.4), weight: .semibold))
                    .foregroundStyle(spine.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(width: height * 0.2)
                    .rotationEffect(.degrees(90))
                    .frame(width: width, height: height * 0.22)
                Text(book.publisher)
                    .font(.system(size: max(5, 7 * scale), weight: .medium))
                    .foregroundStyle(spine.textColor.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .frame(width: width - 4)
                    .padding(.bottom, 4 * scale)
            }
            .padding(.top, 14 * scale)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 2.5, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 3, x: 2, y: 2)
        .rotationEffect(.degrees(spine.tilted ? -2.2 : 0), anchor: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(book.accessibilityName)
    }

    private var displayTitle: String { spine.usesUppercase ? spine.title.uppercased() : spine.title }

    private var titleSize: CGFloat {
        // Narrow spines get smaller type so long titles still fit.
        min(width * 0.52, 24 * scale * 1.3)
    }

    @ViewBuilder
    private var decoration: some View {
        let accent = spine.accentColor
        switch spine.decoration {
        case .bands:
            VStack {
                VStack(spacing: 3 * scale) { band(accent); band(accent) }.padding(.top, 8 * scale)
                Spacer()
                VStack(spacing: 3 * scale) { band(accent); band(accent) }.padding(.bottom, 18 * scale)
            }
        case .block:
            VStack(spacing: 0) {
                accent.frame(height: height * 0.18)
                Spacer()
            }
        case .foot:
            VStack(spacing: 0) {
                Spacer()
                accent.frame(height: height * 0.12)
            }
        case .rule:
            VStack {
                band(accent).padding(.top, 10 * scale)
                Spacer()
            }
        case .dot:
            VStack {
                Circle().fill(accent).frame(width: 7 * scale * 1.3, height: 7 * scale * 1.3).padding(.top, 9 * scale)
                Spacer()
            }
        }
    }

    private func band(_ color: Color) -> some View {
        color.frame(height: max(1, 2 * scale))
    }
}

// MARK: - Flat spine (recommendations shelf)

/// A recommended book lying flat, spine facing out.
struct DLFlatBookView: View {
    let recommendation: DLRecommendation
    var width: CGFloat = 170

    var body: some View {
        HStack(spacing: 6) {
            Text(recommendation.title)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(recommendation.author)
                .font(.system(size: 9, weight: .medium))
                .opacity(0.8)
                .lineLimit(1)
        }
        .foregroundStyle(recommendation.textColor)
        .padding(.horizontal, 8)
        .frame(width: width, height: 20)
        .background(
            ZStack {
                recommendation.backgroundColor
                LinearGradient(colors: [.white.opacity(0.12), .clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recommendation.title) by \(recommendation.author)\(recommendation.from.isEmpty ? "" : ", recommended by \(recommendation.from)")")
    }
}

// MARK: - Cover

/// An original typographic front cover: kicker, a simple vector motif, title and author,
/// with a darker binding strip on the left. Never the real cover art.
struct DLCoverView: View {
    let book: DLBook
    var width: CGFloat = 200

    private var spine: DLSpine { book.spine }
    private var height: CGFloat { width * 1.5 }

    var body: some View {
        ZStack(alignment: .leading) {
            spine.backgroundColor
            LinearGradient(colors: [.white.opacity(0.08), .clear, .black.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(alignment: .leading, spacing: 0) {
                Text((book.subtitle ?? book.genre).uppercased())
                    .font(.system(size: width * 0.045, weight: .semibold, design: .monospaced))
                    .tracking(width * 0.008)
                    .foregroundStyle(spine.accentColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                DLMotifView(motif: book.coverMotif, accent: spine.accentColor, ink: spine.textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: height * 0.36)
                Spacer(minLength: 0)
                Text(spine.usesUppercase ? book.title.uppercased() : book.title)
                    .font(spine.titleFont(size: width * 0.13))
                    .foregroundStyle(spine.textColor)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                Text(book.author.uppercased())
                    .font(.system(size: width * 0.05, weight: .bold))
                    .tracking(width * 0.006)
                    .foregroundStyle(spine.textColor.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 6)
            }
            .padding(.leading, width * 0.12)
            .padding(.trailing, width * 0.08)
            .padding(.vertical, width * 0.09)

            // Binding strip
            LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 0.05)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cover of \(book.accessibilityName)")
    }
}

/// Simple vector motifs drawn with shapes, keyed by the website's `motif` names.
struct DLMotifView: View {
    let motif: String
    let accent: Color
    let ink: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                switch motif {
                case "sun":
                    Circle().fill(accent).frame(width: s * 0.55)
                case "coins":
                    ForEach(0..<4, id: \.self) { i in
                        Ellipse().stroke(accent, lineWidth: 3)
                            .frame(width: s * 0.5, height: s * 0.16)
                            .offset(y: CGFloat(i) * -s * 0.1 + s * 0.15)
                    }
                case "atom":
                    ForEach(0..<3, id: \.self) { i in
                        Ellipse().stroke(accent, lineWidth: 2)
                            .frame(width: s * 0.8, height: s * 0.28)
                            .rotationEffect(.degrees(Double(i) * 60))
                    }
                    Circle().fill(ink).frame(width: s * 0.1)
                case "wave", "pulse":
                    Path { p in
                        let w = geo.size.width
                        p.move(to: CGPoint(x: 0, y: c.y))
                        for x in stride(from: 0, through: w, by: 4) {
                            let amp: CGFloat = motif == "pulse"
                                ? (abs(x - w / 2) < w * 0.12 ? s * 0.3 * sin(x / 6) : 0)
                                : s * 0.1 * sin(x / 18)
                            p.addLine(to: CGPoint(x: x, y: c.y + amp))
                        }
                    }
                    .stroke(accent, lineWidth: 3)
                case "peak", "dune":
                    Path { p in
                        p.move(to: CGPoint(x: geo.size.width * 0.1, y: geo.size.height * 0.85))
                        p.addLine(to: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.15))
                        p.addLine(to: CGPoint(x: geo.size.width * 0.9, y: geo.size.height * 0.85))
                        p.closeSubpath()
                    }
                    .fill(accent)
                case "maze":
                    ForEach(1..<5, id: \.self) { i in
                        Rectangle().stroke(accent, lineWidth: 2)
                            .frame(width: s * 0.2 * CGFloat(i), height: s * 0.2 * CGFloat(i))
                    }
                case "dots":
                    ForEach(0..<9, id: \.self) { i in
                        Circle().fill(i == 4 ? accent : ink.opacity(0.5))
                            .frame(width: s * 0.1)
                            .offset(x: CGFloat(i % 3 - 1) * s * 0.22, y: CGFloat(i / 3 - 1) * s * 0.22)
                    }
                case "burst":
                    ForEach(0..<12, id: \.self) { i in
                        Capsule().fill(accent)
                            .frame(width: 3, height: s * 0.32)
                            .offset(y: -s * 0.22)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                case "cloud":
                    HStack(spacing: -s * 0.12) {
                        Circle().frame(width: s * 0.3)
                        Circle().frame(width: s * 0.42)
                        Circle().frame(width: s * 0.3)
                    }
                    .foregroundStyle(accent)
                case "stone":
                    Circle().fill(accent).frame(width: s * 0.18).offset(x: -s * 0.25)
                    Rectangle().fill(ink.opacity(0.6)).frame(width: s * 0.12, height: s * 0.7).offset(x: s * 0.2)
                case "match":
                    Rectangle().fill(ink.opacity(0.7)).frame(width: 4, height: s * 0.6).offset(y: s * 0.1)
                    Ellipse().fill(accent).frame(width: s * 0.12, height: s * 0.2).offset(y: -s * 0.25)
                case "court":
                    Rectangle().stroke(accent, lineWidth: 2).frame(width: s * 0.5, height: s * 0.85)
                    Rectangle().fill(accent).frame(width: s * 0.5, height: 2)
                case "boat":
                    Path { p in
                        p.move(to: CGPoint(x: c.x - s * 0.3, y: c.y + s * 0.1))
                        p.addLine(to: CGPoint(x: c.x + s * 0.3, y: c.y + s * 0.1))
                        p.addLine(to: CGPoint(x: c.x + s * 0.18, y: c.y + s * 0.25))
                        p.addLine(to: CGPoint(x: c.x - s * 0.18, y: c.y + s * 0.25))
                        p.closeSubpath()
                        p.move(to: CGPoint(x: c.x, y: c.y + s * 0.08))
                        p.addLine(to: CGPoint(x: c.x, y: c.y - s * 0.3))
                        p.addLine(to: CGPoint(x: c.x + s * 0.22, y: c.y + s * 0.02))
                        p.closeSubpath()
                    }
                    .fill(accent)
                default: // "rule" and anything new
                    VStack(spacing: s * 0.06) {
                        Rectangle().fill(accent).frame(width: s * 0.7, height: 2)
                        Rectangle().fill(accent).frame(width: s * 0.45, height: 2)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(DLCatalog.books) { DLSpineView(book: $0) }
        }
        .padding()
    }
    .background(Color.black)
}
