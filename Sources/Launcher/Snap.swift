import AppKit

enum Snap {
    /// Hotkey ids: 2 left half, 3 right half, 4 fill the desktop, 5 enter real full screen, 6 leave it.
    nonisolated static func rect(_ id: UInt32, in visible: CGRect) -> CGRect {
        var f = visible
        if id != 4 { f.size.width /= 2 }
        if id == 3 { f.origin.x += f.width }
        return f
    }

    @MainActor static func apply(_ id: UInt32) {
        guard AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary),
              let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return }
        var ref: AnyObject?
        guard AXUIElementCopyAttributeValue(AXUIElementCreateApplication(pid), kAXFocusedWindowAttribute as CFString, &ref) == .success else { return }
        let window = ref as! AXUIElement
        if id >= 5 { AXUIElementSetAttributeValue(window, "AXFullScreen" as CFString, (id == 5) as CFBoolean); return }
        var pos = CGPoint.zero
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &ref) == .success { AXValueGetValue(ref as! AXValue, .cgPoint, &pos) }
        let top = NSScreen.screens[0].frame.maxY // AX y grows downward from the primary screen's top edge
        let screen = NSScreen.screens.first { $0.frame.contains(CGPoint(x: pos.x, y: top - pos.y - 1)) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let f = rect(id, in: visible)
        var p = CGPoint(x: f.minX, y: top - f.maxY), s = f.size
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &p)!)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &s)!)
    }
}
