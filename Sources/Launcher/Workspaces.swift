import AppKit

/// Workspaces are apps, not Spaces: switching is app activation, which is instant, where a Space switch always goes
/// through the Dock's animation. Workspace 1 is the bare desktop (everything hidden); 2... are the regular apps that
/// have a real window, in launch order, so an app keeps its number while it runs. Fill windows with Cmd+Up.
enum Workspaces {
    @MainActor static func move(_ delta: Int) {
        let apps = apps
        let current = NSWorkspace.shared.frontmostApplication.flatMap { apps.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        move(to: current + delta)
    }

    @MainActor static func move(to index: Int) {
        let apps = apps
        guard apps.indices.contains(index - 1) || index == 0 else { return }
        if index == 0 { apps.forEach { $0.hide() } } else { apps[index - 1].activate() }
    }

    private static var apps: [NSRunningApplication] {
        let windowed = Set((CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []).compactMap { w -> Int32? in
            guard w[kCGWindowLayer as String] as? Int == 0, (w[kCGWindowAlpha as String] as? Double ?? 0) > 0,
                  let b = w[kCGWindowBounds as String] as? [String: Double], b["Width"] ?? 0 >= 200, b["Height"] ?? 0 >= 200 else { return nil }
            return w[kCGWindowOwnerPID as String] as? Int32
        })
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != "com.apple.finder" && windowed.contains($0.processIdentifier) }
            .sorted { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }
    }
}
