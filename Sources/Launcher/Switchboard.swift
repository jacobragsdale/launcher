import AppKit

/// Double-tap Cmd shows the switchboard: one Claude Code session in Rex that Jacob talks to with /voice and that hands
/// work to his other sessions. `ai/switchboard` brings Rex forward on it, starting it first if it isn't running.
enum Switchboard {
    static func show() {
        guard let script = Bundle.main.url(forResource: "switchboard", withExtension: nil, subdirectory: "ai") else { return }
        _ = try? Process.run(script, arguments: []) // ponytail: failures are silent; log stderr if it ever misbehaves
    }
}

/// Cmd pressed and released on its own twice within 0.4s. Any other key or modifier in between cancels it, so a quick
/// Cmd+C, Cmd+V doesn't count.
struct DoubleTap {
    enum Input { case cmd, none, other } // Cmd alone down, every modifier up, anything else

    private var pressed = false, last = -Double.infinity

    mutating func feed(_ input: Input, at t: Double) -> Bool {
        switch input {
        case .cmd: pressed = true
        case .other: pressed = false; last = -.infinity
        case .none:
            guard pressed else { return false }
            pressed = false
            if t - last < 0.4 { last = -.infinity; return true }
            last = t
        }
        return false
    }

    mutating func feed(_ type: CGEventType, _ event: CGEvent) -> Bool {
        let mods = event.flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl, .maskSecondaryFn])
        return feed(type != .flagsChanged ? .other : mods == .maskCommand ? .cmd : mods.isEmpty ? .none : .other, at: Double(event.timestamp) / 1e9)
    }
}
