import AppKit

/// Space switching through SkyLight's private API: instant, no slide animation. The Dock isn't told, so the next
/// three-finger swipe or Mission Control may start from a stale idea of the current space once, then resync.
enum Spaces {
    @MainActor static func move(_ delta: Int) { move { $0 + delta } }
    @MainActor static func move(to index: Int) { move { _ in index } }

    @MainActor private static func move(_ target: (Int) -> Int) {
        typealias Conn = @convention(c) () -> Int32
        typealias Active = @convention(c) (Int32) -> UInt64
        typealias Displays = @convention(c) (Int32) -> Unmanaged<CFArray>
        typealias SetSpace = @convention(c) (Int32, CFString, UInt64) -> Void
        typealias Windows = @convention(c) (Int32, UInt32, CFArray, UInt32, UnsafeMutablePointer<UInt64>, UnsafeMutablePointer<UInt64>) -> Unmanaged<CFArray>?
        typealias Owner = @convention(c) (Int32, UInt32, UnsafeMutablePointer<Int32>) -> Int32
        let sky = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)
        func sym<T>(_ name: String, _: T.Type) -> T? { dlsym(sky, name).map { unsafeBitCast($0, to: T.self) } }
        guard let connection = sym("SLSMainConnectionID", Conn.self), let activeSpace = sym("SLSGetActiveSpace", Active.self),
              let displays = sym("SLSCopyManagedDisplaySpaces", Displays.self), let setSpace = sym("SLSManagedDisplaySetCurrentSpace", SetSpace.self),
              let windows = sym("SLSCopyWindowsWithOptionsAndTags", Windows.self), let owner = sym("SLSGetWindowOwner", Owner.self) else { return }
        let conn = connection(), current = activeSpace(conn)
        guard let display = (displays(conn).takeRetainedValue() as? [[String: Any]])?
                  .first(where: { ($0["Spaces"] as? [[String: Any]])?.contains { $0["ManagedSpaceID"] as? UInt64 == current } == true }),
              let uuid = display["Display Identifier"] as? String,
              let spaces = (display["Spaces"] as? [[String: Any]])?.compactMap({ $0["ManagedSpaceID"] as? UInt64 }),
              let i = spaces.firstIndex(of: current), spaces.indices.contains(target(i)), target(i) != i else { return }
        let target = spaces[target(i)]
        setSpace(conn, uuid as CFString, target)
        // Focus follows: activate whoever owns the first window on the target space.
        var set: UInt64 = 0, clear: UInt64 = 0, pid: Int32 = 0
        if let wid = (windows(conn, 0, [target] as CFArray, 2, &set, &clear)?.takeRetainedValue() as? [UInt32])?.first, owner(conn, wid, &pid) == 0 {
            NSRunningApplication(processIdentifier: pid)?.activate()
        }
    }
}
