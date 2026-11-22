import AppKit
import SwiftUI

@MainActor @Observable final class SearchModel {
    var query = "" { didSet { selected = 0; results = Apps.matches(query, in: apps) } }
    var selected = 0
    var apps: [App] = [] { didSet { results = Apps.matches(query, in: apps) } }
    private(set) var results: [App] = []
    @ObservationIgnored var onOpen: () -> Void = {}
    @ObservationIgnored private var iconAppearance: NSAppearance.Name?

    /// Assigns only on change, so the usual rescan (nothing installed, no launches counted) costs the UI nothing.
    // ponytail: icon style changes (tinted/clear) keep old icons until relaunch; hook the setting's notification if that bites
    func refresh() async {
        let appearance = NSApp.effectiveAppearance.name, old = appearance == iconAppearance ? apps : []
        let new = await Task.detached { Apps.scan(reusing: old, appearance: appearance) }.value
        iconAppearance = appearance
        if new != apps { apps = new }
    }

    func move(_ d: Int) {
        let n = results.count
        guard n > 0 else { return }
        selected = (selected + d + n) % n
    }

    func open() {
        let r = results
        guard r.indices.contains(selected) else { return }
        Apps.open(r[selected])
        onOpen()
    }
}

struct SearchView: View {
    @Bindable var model: SearchModel
    var hide: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search apps", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .light))
                .padding(16)
                .focused($focused)
                .onSubmit { model.open() }
                .onKeyPress(.downArrow) { model.move(1); return .handled }
                .onKeyPress(.upArrow) { model.move(-1); return .handled }
                .onKeyPress(.escape) { hide(); return .handled }
            let results = model.results
            if !results.isEmpty {
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        // Rows are identified by position: typing refills the same rows instead of diffing inserts and removals
                        LazyVStack(spacing: 2) {
                            ForEach(results.indices, id: \.self) { i in
                                Row(app: results[i], selected: i == model.selected)
                                    .onTapGesture { model.selected = i; model.open() }
                            }
                        }
                        .padding(8)
                    }
                    // 44pt rows + 2pt gaps; the half row peeking out says "scroll me"
                    .frame(height: min(CGFloat(results.count), 8.5) * 46 + 14)
                    .onChange(of: model.selected) { proxy.scrollTo(model.selected) }
                }
            }
        }
        .frame(width: 640)
        // Behind the content, not wrapping it: wrapped, the glass re-processed the list on every show, keystroke and scroll
        .background { Color.clear.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20)) }
        .frame(maxHeight: .infinity, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in focused = true }
    }
}

/// Its own view so an arrow key re-renders just the two rows whose `selected` flipped.
struct Row: View {
    let app: App
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon { Image(decorative: icon, scale: 2) } else { Color.clear.frame(width: 32, height: 32) }
            Text(app.name).font(.system(size: 16))
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(selected ? Color.accentColor.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

final class Panel: NSPanel {
    let model = SearchModel()

    init() {
        super.init(contentRect: .init(x: 0, y: 0, width: 640, height: 480),
                   styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                   backing: .buffered, defer: false)
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        isMovableByWindowBackground = true
        model.onOpen = { [weak self] in self?.hide() }
        contentView = NSHostingView(rootView: SearchView(model: model, hide: { [weak self] in self?.hide() }))
        Task { await model.refresh(); prewarm() }
        NotificationCenter.default.addObserver(self, selector: #selector(hide), name: NSWindow.didResignKeyNotification, object: self)
    }

    override var canBecomeKey: Bool { true }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "q" {
            NSApp.terminate(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    @objc func hide() { orderOut(nil) }

    /// Pays the first show's one-time cost (window surface, SwiftUI's first layout of the list) at launch, invisibly.
    private func prewarm() {
        guard !isVisible else { return }
        alphaValue = 0
        orderFrontRegardless()
        displayIfNeeded()
        orderOut(nil)
        alphaValue = 1
    }

    func toggle() {
        if isKeyWindow { return hide() }
        model.query = "" // didSet also resets the selection
        Task { await model.refresh() }
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let f = screen?.visibleFrame {
            setFrameOrigin(.init(x: f.midX - frame.width / 2, y: f.maxY - f.height * 0.2 - frame.height))
        }
        makeKeyAndOrderFront(nil)
    }
}
