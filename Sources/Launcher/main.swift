import AppKit
import Carbon
import ServiceManagement

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = Panel()

    func applicationDidFinishLaunching(_: Notification) {
        if Bundle.main.bundlePath.hasPrefix("/Applications/") { try? SMAppService.mainApp.register() }

        var hotKey: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey), EventHotKeyID(signature: 0x4C4E4348, id: 1),
                            GetApplicationEventTarget(), 0, &hotKey)
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            MainActor.assumeIsolated { (NSApp.delegate as! AppDelegate).panel.toggle() }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
