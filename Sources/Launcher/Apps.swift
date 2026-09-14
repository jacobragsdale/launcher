import AppKit

struct App: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    var id: URL { url }
}

enum Apps {
    nonisolated static let dirs = [
        "/Applications", "/System/Applications",
        "/System/Cryptexes/App/System/Applications", NSHomeDirectory() + "/Applications",
    ].map { URL(fileURLWithPath: $0) }

    // ponytail: rescan-on-show, add NSMetadataQuery if apps in deeper folders are ever missed
    nonisolated static func scan() -> [App] {
        let fm = FileManager.default
        var seen = Set<URL>()
        var out: [App] = []
        func visit(_ dir: URL, depth: Int) {
            let items = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)) ?? []
            for url in items {
                if url.pathExtension == "app" {
                    if seen.insert(url.resolvingSymlinksInPath()).inserted {
                        out.append(App(url: url, name: fm.displayName(atPath: url.path)))
                    }
                } else if depth < 1, (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    visit(url, depth: depth + 1)
                }
            }
        }
        dirs.forEach { visit($0, depth: 0) }
        return out
    }

    nonisolated static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Lower is better: 0 prefix, 1 word prefix, 2 initials, 3 subsequence. nil = no match.
    nonisolated static func score(query: String, name: String) -> Int? {
        let q = fold(query), n = fold(name)
        if q.isEmpty || n.hasPrefix(q) { return 0 }
        let words = n.split(separator: " ")
        if words.contains(where: { $0.hasPrefix(q) }) { return 1 }
        if String(words.compactMap(\.first)).hasPrefix(q) { return 2 }
        var rest = n[...]
        for c in q {
            guard let i = rest.firstIndex(of: c) else { return nil }
            rest = rest[rest.index(after: i)...]
        }
        return 3
    }

    nonisolated static var counts: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: "counts") as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "counts") }
    }

    nonisolated static func matches(_ query: String, in apps: [App]) -> [App] {
        let counts = counts
        return apps
            .compactMap { app in score(query: query, name: app.name).map { (app, $0, -counts[app.url.path, default: 0]) } }
            .sorted { ($0.1, $0.2, $0.0.name) < ($1.1, $1.2, $1.0.name) }
            .prefix(8).map(\.0)
    }

    @MainActor static func open(_ app: App) {
        counts[app.url.path, default: 0] += 1
        NSWorkspace.shared.openApplication(at: app.url, configuration: .init())
    }

    @MainActor private static var icons: [URL: NSImage] = [:]
    @MainActor static func icon(_ app: App) -> NSImage {
        if let i = icons[app.url] { return i }
        let i = NSWorkspace.shared.icon(forFile: app.url.path)
        icons[app.url] = i
        return i
    }
}
