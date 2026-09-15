import AppKit

/// Space switching the way macOS does it: activate something that lives on the target space and let the Dock go there.
/// Driving the window server directly (SLSManagedDisplaySetCurrentSpace) leaves full-screen windows stuck on screen.
enum Spaces {
    @MainActor static func move(_ delta: Int) { move { $0 + delta } }
    @MainActor static func move(to index: Int) { move { _ in index } }

    @MainActor private static func move(_ target: (Int) -> Int) {
        typealias Conn = @convention(c) () -> Int32
        typealias Active = @convention(c) (Int32) -> UInt64
        typealias Displays = @convention(c) (Int32) -> Unmanaged<CFArray>
        typealias MoveWindows = @convention(c) (Int32, CFArray, UInt64) -> Void
        let sky = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)
        func sym<T>(_ name: String, _: T.Type) -> T? { dlsym(sky, name).map { unsafeBitCast($0, to: T.self) } }
        guard let connection = sym("SLSMainConnectionID", Conn.self), let activeSpace = sym("SLSGetActiveSpace", Active.self),
              let displays = sym("SLSCopyManagedDisplaySpaces", Displays.self),
              let moveWindows = sym("SLSMoveWindowsToManagedSpace", MoveWindows.self) else { return }
        let conn = connection(), current = activeSpace(conn)
        guard let spaces = (displays(conn).takeRetainedValue() as? [[String: Any]])?
                  .lazy.compactMap({ $0["Spaces"] as? [[String: Any]] }).first(where: { $0.contains { $0["ManagedSpaceID"] as? UInt64 == current } }),
              let i = spaces.firstIndex(where: { $0["ManagedSpaceID"] as? UInt64 == current }),
              spaces.indices.contains(target(i)), target(i) != i, let id = spaces[target(i)]["ManagedSpaceID"] as? UInt64 else { return }
        if let pid = spaces[target(i)]["pid"] as? Int32 { // a full-screen space belongs to one app: activating it goes there
            NSRunningApplication(processIdentifier: pid)?.activate()
            return
        }
        // A desktop: park an invisible window of ours on it and make it key, so the Dock follows; then hand focus to Finder.
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1, height: 1), styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.alphaValue = 0.01
        window.orderFront(nil)
        moveWindows(conn, [UInt32(window.windowNumber)] as CFArray, id)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            window.close()
            NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == "com.apple.finder" }?.activate()
        }
    }
}
