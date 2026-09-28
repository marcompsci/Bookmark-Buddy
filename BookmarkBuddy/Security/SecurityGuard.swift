// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import UIKit
import MachO

/// Runtime security checks. All checks are no-ops in the Simulator so Xcode
/// debugging is never blocked during development.
final class SecurityGuard {

    static let shared = SecurityGuard()
    private init() {}

    // MARK: - Jailbreak detection

    /// Returns `true` if the device shows signs of being jailbroken.
    /// Always `false` in the Simulator.
    var isCompromised: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return detectJailbreakFiles()
            || detectSandboxEscape()
            || detectSuspiciousDylibs()
        #endif
    }

    private func detectJailbreakFiles() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/bin/sh",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/cache/apt/",
            "/var/binpack"
        ]
        return suspiciousPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private func detectSandboxEscape() -> Bool {
        let probe = "/private/jailbreak_\(UUID().uuidString)"
        do {
            try "probe".write(toFile: probe, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: probe)
            return true
        } catch {
            return false
        }
    }

    private func detectSuspiciousDylibs() -> Bool {
        let count = _dyld_image_count()
        for i in 0 ..< count {
            guard let name = _dyld_get_image_name(i).map(String.init(cString:)) else { continue }
            if name.contains("MobileSubstrate") || name.contains("substitute") || name.contains("cycript") {
                return true
            }
        }
        return false
    }

    // MARK: - Debugger detection

    /// Returns `true` if a debugger is attached. Always `false` in DEBUG builds.
    var isDebugged: Bool {
        #if DEBUG
        return false
        #else
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        return (info.kp_proc.p_flag & P_TRACED) != 0
        #endif
    }

    // MARK: - Screenshot monitoring

    private var screenshotObserver: NSObjectProtocol?

    /// Registers a handler called each time the user takes a screenshot.
    func startScreenshotMonitoring(handler: @escaping () -> Void) {
        screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in handler() }
    }

    func stopScreenshotMonitoring() {
        if let obs = screenshotObserver {
            NotificationCenter.default.removeObserver(obs)
            screenshotObserver = nil
        }
    }

    // MARK: - Startup audit

    /// Returns a non-nil warning message when the environment is unsafe.
    func auditEnvironment() -> String? {
        if isCompromised { return "This device appears to be jailbroken. Bookmark Buddy cannot run securely." }
        if isDebugged    { return "A debugger is attached. Bookmark Buddy cannot run securely." }
        return nil
    }
}
