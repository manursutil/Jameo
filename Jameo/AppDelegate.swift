import AppKit
import Carbon
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = JameoViewModel()
    private lazy var panelController = SpotlightPanelController(viewModel: viewModel)
    private var hotKeyManager: HotKeyManager?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setUpMenuBarItem()
        setUpHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager = nil
    }

    @objc private func openJameo() {
        panelController.show()
    }

    @objc private func openSettings() {
        let window = settingsWindow ?? makeSettingsWindow()
        settingsWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func quitJameo() {
        NSApp.terminate(nil)
    }

    private func setUpMenuBarItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "sparkle.magnifyingglass",
            accessibilityDescription: "Jameo"
        )
        statusItem.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: String(localized: "Open Jameo"), action: #selector(openJameo), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: String(localized: "Settings..."), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: String(localized: "Quit Jameo"), action: #selector(quitJameo), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    private func setUpHotKey() {
        hotKeyManager = HotKeyManager(keyCode: UInt32(kVK_Space), modifiers: cmdKey | shiftKey) { [weak self] in
            self?.panelController.toggle()
        }
    }

    private func makeSettingsWindow() -> NSWindow {
        let hostingView = NSHostingView(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = String(localized: "Settings")
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()

        return window
    }
}
