import AppKit
import Carbon
import ServiceManagement

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = Panel()

    func applicationDidFinishLaunching(_: Notification) {
        if Bundle.main.bundlePath.hasPrefix("/Applications/") { try? SMAppService.mainApp.register() }

        for (id, key, mods) in [(1, kVK_Space, cmdKey), (2, kVK_LeftArrow, cmdKey), (3, kVK_RightArrow, cmdKey), (4, kVK_UpArrow, cmdKey),
                                (5, kVK_UpArrow, cmdKey | shiftKey), (6, kVK_DownArrow, cmdKey | shiftKey),
                                (7, kVK_LeftArrow, cmdKey | shiftKey), (8, kVK_RightArrow, cmdKey | shiftKey)] {
            var hotKey: EventHotKeyRef?
            RegisterEventHotKey(UInt32(key), UInt32(mods), EventHotKeyID(signature: 0x4C4E4348, id: UInt32(id)),
                                GetApplicationEventTarget(), 0, &hotKey)
        }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            MainActor.assumeIsolated { hk.id == 1 ? (NSApp.delegate as! AppDelegate).panel.toggle() : hk.id >= 7 ? Spaces.move(hk.id == 7 ? -1 : 1) : Snap.apply(hk.id) }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
