import AppKit
import Combine
import SwiftUI

@MainActor
final class SpotlightPanelController: NSObject, NSWindowDelegate {
    private enum Layout {
        static let width: CGFloat = 620
        static let collapsedHeight: CGFloat = 82
        static let expandedHeight: CGFloat = 360
        static let topOffset: CGFloat = 96
        static let cornerRadius: CGFloat = 20
    }

    private let viewModel: LumaViewModel
    private var panel: SpotlightPanel?
    private var escapeMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []

    init(viewModel: LumaViewModel) {
        self.viewModel = viewModel
        super.init()
        observeContentChanges()
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel

        viewModel.reset()
        position(panel)
        installEscapeMonitor()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        viewModel.requestFocus()
    }

    func hide() {
        panel?.orderOut(nil)
        removeEscapeMonitor()
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func makePanel() -> SpotlightPanel {
        let contentView = ContentView(viewModel: viewModel)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        let panel = SpotlightPanel(
            contentRect: NSRect(x: 0, y: 0, width: Layout.width, height: Layout.collapsedHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        return panel
    }

    private func observeContentChanges() {
        viewModel.$answer
            .combineLatest(viewModel.$isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.resizePanelForCurrentContent()
            }
            .store(in: &cancellables)
    }

    private func installEscapeMonitor() {
        guard escapeMonitor == nil else { return }

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else {
                return event
            }

            self?.hide()
            return nil
        }
    }

    private func removeEscapeMonitor() {
        guard let escapeMonitor else { return }

        NSEvent.removeMonitor(escapeMonitor)
        self.escapeMonitor = nil
    }

    private func resizePanelForCurrentContent() {
        guard let panel else { return }

        let targetHeight = viewModel.answer.isEmpty && !viewModel.isLoading ? Layout.collapsedHeight : Layout.expandedHeight
        var frame = panel.frame
        let heightDelta = targetHeight - frame.height
        frame.size.height = targetHeight
        frame.origin.y -= heightDelta
        panel.setFrame(frame, display: true, animate: true)
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let x = visibleFrame.midX - panelFrame.width / 2
        let y = visibleFrame.maxY - panelFrame.height - Layout.topOffset

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

final class SpotlightPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            orderOut(nil)
            return
        }

        super.keyDown(with: event)
    }
}
