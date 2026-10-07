// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Drives a Guide Me walkthrough. Owned by AppRouter and shared via the environment.
@Observable
@MainActor
final class GuideCoordinator {
    private(set) var walkthrough: GuideWalkthrough?
    private(set) var stepIndex: Int = 0

    var currentStep: GuideStep? {
        guard let walkthrough, stepIndex < walkthrough.steps.count else { return nil }
        return walkthrough.steps[stepIndex]
    }

    var stepCount: Int { walkthrough?.steps.count ?? 0 }

    var isLastStep: Bool {
        guard let walkthrough else { return false }
        return stepIndex >= walkthrough.steps.count - 1
    }

    var isActive: Bool { walkthrough != nil }

    func start(_ walkthrough: GuideWalkthrough) {
        self.walkthrough = walkthrough
        stepIndex = 0
    }

    /// Looks up a walkthrough by ID from the app's walkthrough catalog.
    func start(_ walkthroughID: String) {
        let catalog: [GuideWalkthrough] = [DemoData.triviaNightWalkthrough]
        guard let walkthrough = catalog.first(where: { $0.id == walkthroughID }) else { return }
        start(walkthrough)
    }

    func advance() {
        guard let walkthrough else { return }
        if stepIndex < walkthrough.steps.count - 1 {
            stepIndex += 1
        } else {
            end()
        }
    }

    func end() {
        walkthrough = nil
        stepIndex = 0
    }

    /// Called when the user naturally performs an action matching the current step's target.
    /// Advances automatically so the guide feels responsive to real navigation.
    func reached(_ target: GuideTarget) {
        guard currentStep?.target == target else { return }
        advance()
    }

    /// Steps back to the first occurrence of `target` in the walkthrough.
    /// Used when a sheet closes mid-guide and the user needs to re-trigger it.
    func rewind(to target: GuideTarget) {
        guard let walkthrough else { return }
        if let index = walkthrough.steps.firstIndex(where: { $0.target == target }) {
            stepIndex = index
        }
    }
}
