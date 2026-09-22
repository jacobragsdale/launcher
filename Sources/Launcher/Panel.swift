import AppKit
import SwiftUI

@MainActor @Observable final class SearchModel {
    var query = ""
    var selected = 0
    var apps: [App] = []
    var onOpen: () -> Void = {}
    var results: [App] { Apps.matches(query, in: apps) }

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
                        LazyVStack(spacing: 2) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { i, app in
                                HStack(spacing: 12) {
                                    Image(nsImage: Apps.icon(app)).resizable().frame(width: 32, height: 32)
                                    Text(app.name).font(.system(size: 16))
                                    Spacer()
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(i == model.selected ? Color.accentColor.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())
                                .onTapGesture { model.selected = i; model.open() }
                            }
                        }
                        .padding(8)
                    }
                    // 44pt rows + 2pt gaps; the half row peeking out says "scroll me"
                    .frame(height: min(CGFloat(results.count), 8.5) * 46 + 14)
                    .onChange(of: model.selected) {
                        let r = model.results
                        if r.indices.contains(model.selected) { proxy.scrollTo(r[model.selected].id) }
                    }
                }
            }
        }
        .frame(width: 640)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: model.query) { model.selected = 0 }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in focused = true }
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

    func toggle() {
        if isKeyWindow { return hide() }
        model.query = ""
        model.selected = 0
        Task { model.apps = await Task.detached { Apps.scan() }.value }
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let f = screen?.visibleFrame {
            setFrameOrigin(.init(x: f.midX - frame.width / 2, y: f.maxY - f.height * 0.2 - frame.height))
        }
        makeKeyAndOrderFront(nil)
    }
}
