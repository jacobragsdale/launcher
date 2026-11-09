import AppKit
import Carbon

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = Panel()
    var doubleTap = DoubleTap()
    var tap: CFMachPort?

    func applicationDidFinishLaunching(_: Notification) {
        let digits = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
        for (id, key, mods) in [(1, kVK_Space, cmdKey), (2, kVK_LeftArrow, cmdKey), (3, kVK_RightArrow, cmdKey), (4, kVK_UpArrow, cmdKey),
                                (5, kVK_UpArrow, cmdKey | shiftKey), (6, kVK_DownArrow, cmdKey | shiftKey),
                                (7, kVK_LeftArrow, cmdKey | shiftKey), (8, kVK_RightArrow, cmdKey | shiftKey)]
                                + digits.enumerated().map { (11 + $0.offset, $0.element, cmdKey) } { // 11...19: Cmd+1...9 jump to a workspace
            var hotKey: EventHotKeyRef?
            RegisterEventHotKey(UInt32(key), UInt32(mods), EventHotKeyID(signature: 0x4C4E4348, id: UInt32(id)),
                                GetApplicationEventTarget(), 0, &hotKey)
        }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            MainActor.assumeIsolated { hk.id == 1 ? (NSApp.delegate as! AppDelegate).panel.toggle() : hk.id >= 11 ? Workspaces.move(to: Int(hk.id) - 11) : hk.id >= 7 ? Workspaces.move(hk.id == 7 ? -1 : 1) : Snap.apply(hk.id) }
            return noErr
        }, 1, &spec, nil, nil)

        // Modifier-only, so no Carbon hotkey can express it. An active tap (it passes every event through untouched) needs
        // only the Accessibility trust Snap asks for; a listen-only tap or NSEvent monitor would also need Input Monitoring.
        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue | 1 << CGEventType.keyDown.rawValue)
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, _ in
            MainActor.assumeIsolated {
                let me = NSApp.delegate as! AppDelegate
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput { me.tap.map { CGEvent.tapEnable(tap: $0, enable: true) } }
                else if me.doubleTap.feed(type, event) { me.panel.toggle(ai: true) }
            }
            return .passUnretained(event)
        }, userInfo: nil)
        tap.map { CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, $0, 0), .commonModes) }
    }
}

// Apps opened via NSWorkspace inherit this process's env; a `make install` from a herdr/Claude shell would
// otherwise leak HERDR_ENV/CLAUDE_CODE_CHILD_SESSION into every Ghostty launched from here.
for k in ProcessInfo.processInfo.environment.keys where k.hasPrefix("HERDR_") || k.hasPrefix("CLAUDE") || k == "AI_AGENT" { unsetenv(k) }

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
