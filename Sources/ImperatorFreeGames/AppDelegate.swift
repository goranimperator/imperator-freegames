import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: MenuBarPanel!
    private var gameStore: GameStore!
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var badgeDot: NSView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator FreeGames", forKey: "processName")

        gameStore = GameStore()

        setupStatusItem()
        setupPanel()
        observeUnread()

        NotificationManager.shared.requestAuthorization()

        Task {
            await gameStore.fetch()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.gameStore.fetch()
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        button.image = SigilIcon.gamepadImage(size: 18)
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPanel() {
        let quitAction = {
            NSApplication.shared.terminate(nil)
        }
        let store = gameStore!
        let refreshAction: () -> Void = {
            Task {
                await store.fetch()
            }
        }

        // A MenuBarPanel rather than an NSPopover. macOS 27 draws its own menu
        // bar panels as plain rounded rectangles with a 17.5 pt corner, no
        // arrow and no animation, and an NSPopover draws none of that: 26.25 pt
        // with an arrow from a current binary, 9.5 from an old-stamped one, and
        // it exposes neither for adjustment. See MenuBarPanel for the
        // measurements, taken off Control Centre's Wi-Fi panel.
        panel = MenuBarPanel(
            content: PopoverContentView(quitAction: quitAction, refreshAction: refreshAction)
                .environmentObject(gameStore),
            width: 340
        )
        // NSPopover highlights the status item it is anchored to for as long as
        // it is attached, which is where the rounded backing behind the icon
        // comes from. A panel gets none of that, so the pressed state is driven
        // by hand here, and dropped whenever the panel closes itself: on a click
        // outside, on Escape, or on the status item's own second click.
        panel.onClose = { [weak self] in
            self?.statusItem.button?.isHighlighted = false
        }
    }

    private func observeUnread() {
        gameStore.$hasUnread
            .receive(on: RunLoop.main)
            .sink { [weak self] hasUnread in
                self?.updateBadge(hasUnread)
            }
            .store(in: &cancellables)
    }

    private func updateBadge(_ show: Bool) {
        badgeDot?.removeFromSuperview()
        badgeDot = nil

        guard show, let button = statusItem.button else { return }

        let dot = NSView(frame: NSRect(
            x: button.bounds.width - 8,
            y: button.bounds.height - 8,
            width: 8,
            height: 8
        ))
        dot.wantsLayer = true
        dot.layer?.backgroundColor = AppColors.badgeRedNS.cgColor
        dot.layer?.cornerRadius = 4
        button.addSubview(dot)
        badgeDot = dot
    }

    @objc private func togglePopover() {
        if panel.isShown {
            panel.close()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button else { return }
        panel.show(from: button)
        button.isHighlighted = true
        gameStore.markAsRead()
        NSApp.activate(ignoringOtherApps: true)
    }
}
