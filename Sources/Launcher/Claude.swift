import AppKit

/// Double-tap Cmd opens the panel in Claude mode; Enter hands the text to Claude Code (Haiku), which works from the
/// bundled `ai/` folder: `prompt.md` is its whole system prompt and the scripts beside it are all it may run.
enum Claude {
    nonisolated static func ask(_ request: String) async -> String {
        await Task.detached {
            let p = Process(), input = Pipe(), output = Pipe()
            p.executableURL = URL(fileURLWithPath: NSHomeDirectory() + "/.local/bin/claude")
            p.currentDirectoryURL = Bundle.main.url(forResource: "ai", withExtension: nil)
            // No user settings, MCP servers or memory: no hooks or plugins to load, and nothing but prompt.md to follow
            p.arguments = ["-p", "--model", "haiku", "--system-prompt-file", "prompt.md", "--tools", "Bash",
                           "--allowedTools", "Bash(./lights*)", "--setting-sources", "", "--settings", #"{"autoMemoryEnabled":false}"#,
                           "--strict-mcp-config", "--disable-slash-commands", "--no-session-persistence"]
            p.standardInput = input // not an argument: a request starting with "-" would parse as a flag
            p.standardOutput = output
            p.standardError = output
            do { try p.run() } catch { return "Couldn't start Claude Code: \(error.localizedDescription)" }
            input.fileHandleForWriting.write(Data(request.utf8))
            try? input.fileHandleForWriting.close()
            let reply = output.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return String(decoding: reply, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
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
