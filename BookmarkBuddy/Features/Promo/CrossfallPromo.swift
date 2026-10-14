// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import StoreKit
import SwiftUI

/// Cross-promotion for Crossfall, another Phoronomic Studios game.
///
/// Tapping "Get Crossfall" opens Crossfall's App Store page inside Bookmark Buddy.
/// Until Crossfall 1.0 is live on the App Store, the page can't load, so we fall back to
/// Crossfall's public TestFlight beta link.
enum CrossfallPromo {
    /// Crossfall's App Store (Apple) ID.
    static let appStoreID = "6821776754"
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    static let betaURL = URL(string: "https://testflight.apple.com/join/Ncy29VUy")!
    static let tagline = "Crossword meets falling blocks"
}

struct CrossfallPromoCard: View {
    @AppStorage(StorageKeys.crossfallPromoHiddenUntil) private var hiddenUntil: Double = 0
    @State private var showsStore = false
    @Environment(\.openURL) private var openURL

    private var isHidden: Bool { Date.now.timeIntervalSince1970 < hiddenUntil }

    var body: some View {
        if !isHidden {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(alignment: .top) {
                    Text("MORE FROM PHORONOMIC STUDIOS")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                    Spacer()
                    Button {
                        // Hide for two weeks.
                        hiddenUntil = Date.now.addingTimeInterval(14 * 86_400).timeIntervalSince1970
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Hide Crossfall promo")
                }

                HStack(alignment: .center, spacing: Theme.Spacing.md) {
                    Image("CrossfallIcon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.Palette.hairline, lineWidth: 1))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crossfall")
                            .font(.bbTitle3)
                            .foregroundStyle(Theme.Palette.parchment)
                        Text(CrossfallPromo.tagline)
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.gold)
                        Text("Solve the crossword, watch your words fall, and find what's hiding in the stack. A new puzzle every day.")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                PrimaryButton(title: "Get Crossfall", systemImage: "arrow.down.app.fill") {
                    Analytics.log(.crossfallPromoTapped, ["where": "today"])
                    showsStore = true
                }
            }
            .bbCard()
            .sheet(isPresented: $showsStore) {
                AppStoreProductSheet(appStoreID: CrossfallPromo.appStoreID, onFinish: { showsStore = false }) { loaded in
                    if !loaded {
                        showsStore = false
                        // Not on the App Store yet (or offline): try the App Store link, then the beta.
                        openURL(CrossfallPromo.betaURL)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
}

/// Apple's in-app App Store page (SKStoreProductViewController), so people can tap Get without leaving.
struct AppStoreProductSheet: UIViewControllerRepresentable {
    let appStoreID: String
    /// Called when the person taps Done on the store page.
    var onFinish: () -> Void = {}
    /// Called once the page has (or hasn't) loaded.
    let onLoad: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> SKStoreProductViewController {
        let controller = SKStoreProductViewController()
        controller.delegate = context.coordinator
        controller.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appStoreID]) { loaded, _ in
            DispatchQueue.main.async { onLoad(loaded) }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: SKStoreProductViewController, context: Context) {}

    final class Coordinator: NSObject, SKStoreProductViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            onFinish()
        }
    }
}
