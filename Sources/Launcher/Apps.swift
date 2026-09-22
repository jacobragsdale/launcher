import AppKit

struct App: Hashable, Sendable {
    let url: URL
    let name: String
    var uses = 0
    var icon: CGImage? = nil
}

enum Apps {
    nonisolated static let dirs = [
        "/Applications", "/System/Applications",
        "/System/Cryptexes/App/System/Applications", NSHomeDirectory() + "/Applications",
    ].map { URL(fileURLWithPath: $0) }

    // ponytail: rescan-on-show, add NSMetadataQuery if apps in deeper folders are ever missed
    /// Icons are rendered here, off the main thread, and carried over from `old` so a rescan only draws new apps.
    nonisolated static func scan(reusing old: [App], appearance: NSAppearance.Name) -> [App] {
        let fm = FileManager.default
        let icons = Dictionary(old.map { ($0.url, $0.icon) }) { a, _ in a }
        var seen = Set<URL>()
        var out: [App] = []
        func visit(_ dir: URL, depth: Int) {
            let items = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)) ?? []
            for url in items {
                if url.pathExtension == "app" {
                    if seen.insert(url.resolvingSymlinksInPath()).inserted {
                        // macOS counts launches from anywhere (Dock, Finder, us), so ranking works from day one
                        let uses = MDItemCreateWithURL(nil, url as CFURL).flatMap { MDItemCopyAttribute($0, "kMDItemUseCount" as CFString) as? Int } ?? 0
                        out.append(App(url: url, name: fm.displayName(atPath: url.path), uses: uses, icon: icons[url] ?? render(url, appearance)))
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

    nonisolated static func matches(_ query: String, in apps: [App]) -> [App] {
        apps
            .compactMap { app in score(query: query, name: app.name).map { (app, $0) } }
            .sorted { ($0.1, -$0.0.uses, $0.0.name) < ($1.1, -$1.0.uses, $1.0.name) }
            .map(\.0)
    }

    @MainActor static func open(_ app: App) {
        NSWorkspace.shared.openApplication(at: app.url, configuration: .init())
    }

    /// 32pt @2x bitmap: the system icon is lazily drawn at up to 1024px, ~12ms each cold, which stalls scrolling on main.
    nonisolated static func render(_ url: URL, _ appearance: NSAppearance.Name) -> CGImage? {
        let image = NSWorkspace.shared.icon(forFile: url.path)
        guard let ctx = CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else { return nil }
        NSAppearance(named: appearance)?.performAsCurrentDrawingAppearance {
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
            image.draw(in: CGRect(x: 0, y: 0, width: 64, height: 64))
            NSGraphicsContext.current = nil
        }
        return ctx.makeImage()
    }
}
