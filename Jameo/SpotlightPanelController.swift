import AppKit
import Combine
import SwiftUI

@MainActor
final class SpotlightPanelController: NSObject, NSWindowDelegate {
    private enum Layout {
        static let width: CGFloat = 620
        static let collapsedHeight: CGFloat = 64
        static let topOffset: CGFloat = 96
        static let bottomOffset: CGFloat = 48
        static let cornerRadius: CGFloat = 32
    }

    private let viewModel: JameoViewModel
    private var panel: SpotlightPanel?
    private var escapeMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []
    private lazy var screenContextProvider = CurrentScreenContextProvider(
        panelProvider: { [weak self] in
            self?.panel
        },
        restorePanel: { [weak self] panel in
            self?.restorePanel(panel)
        }
    )

    init(viewModel: JameoViewModel) {
        self.viewModel = viewModel
        super.init()
        self.viewModel.screenContextImageProvider = { [weak self] in
            try await self?.screenContextProvider.captureImage()
        }
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

        if !JameoSettings.preservePanelState {
            viewModel.reset()
        }

        viewModel.refreshScreenContextAvailability()
        position(panel)
        installEscapeMonitor()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        schedulePanelResize()
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
        let panelShape = RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
        let contentView = ContentView(viewModel: viewModel)
            .glassEffect(.regular, in: panelShape)
            .overlay {
                panelShape
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
            }
            .clipShape(panelShape)

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
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        return panel
    }

    private func observeContentChanges() {
        Publishers.CombineLatest3(viewModel.$answer, viewModel.$isLoading, viewModel.$didSubmitWithScreenContext)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.schedulePanelResize()
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

    private func schedulePanelResize() {
        DispatchQueue.main.async { [weak self] in
            self?.resizePanelForCurrentContent()
        }
    }

    private func resizePanelForCurrentContent() {
        guard let panel else { return }

        panel.contentView?.layoutSubtreeIfNeeded()

        let measuredHeight = panel.contentView?.fittingSize.height ?? Layout.collapsedHeight
        let targetHeight = min(
            max(measuredHeight, Layout.collapsedHeight),
            maximumPanelHeight(for: panel)
        )
        var frame = panel.frame
        guard abs(frame.height - targetHeight) > 0.5 else { return }

        let heightDelta = targetHeight - frame.height
        frame.size.height = targetHeight
        frame.origin.y -= heightDelta
        panel.setFrame(frame, display: true, animate: true)
        panel.invalidateShadow()
    }

    private func maximumPanelHeight(for panel: NSPanel) -> CGFloat {
        let visibleFrame = (panel.screen ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame

        guard let visibleFrame else {
            return CGFloat.greatestFiniteMagnitude
        }

        return max(
            Layout.collapsedHeight,
            visibleFrame.height - Layout.topOffset - Layout.bottomOffset
        )
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

    private func restorePanel(_ panel: NSPanel) {
        position(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        viewModel.requestFocus()
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
