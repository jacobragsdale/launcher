import AppKit

/// Workspaces are apps, not Spaces: switching is app activation, which is instant, where a Space switch always goes
/// through the Dock's animation. Workspace N is the Nth regular app with a real window, in launch order, so an app
/// keeps its number while it runs. Fill windows with Cmd+Up.
enum Workspaces {
    @MainActor static func move(_ delta: Int) {
        let apps = apps
        guard let current = NSWorkspace.shared.frontmostApplication.flatMap({ apps.firstIndex(of: $0) }) else { return move(to: 0) }
        move(to: current + delta)
    }

    @MainActor static func move(to index: Int) {
        let apps = apps
        if apps.indices.contains(index) { apps[index].activate() }
    }

    private static var apps: [NSRunningApplication] {
        let windowed = Set((CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []).compactMap { w -> Int32? in
            guard w[kCGWindowLayer as String] as? Int == 0, (w[kCGWindowAlpha as String] as? Double ?? 0) > 0,
                  let b = w[kCGWindowBounds as String] as? [String: Double], b["Width"] ?? 0 >= 200, b["Height"] ?? 0 >= 200 else { return nil }
            return w[kCGWindowOwnerPID as String] as? Int32
        })
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != "com.apple.finder" && windowed.contains($0.processIdentifier) }
            .map { ($0, $0.launchDate ?? .distantPast) } // each launchDate is an IPC; don't redo it per sort comparison
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }
}
