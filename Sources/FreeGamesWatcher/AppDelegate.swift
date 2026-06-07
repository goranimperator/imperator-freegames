import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var gameStore: GameStore!
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var badgeDot: NSView?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator Free Games", forKey: "processName")

        gameStore = GameStore()

        setupStatusItem()
        setupPopover()
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

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        button.image = SigilIcon.gamepadImage(size: 18)
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient
        popover.animates = true

        let quitAction = {
            NSApplication.shared.terminate(nil)
        }
        let store = gameStore!
        let refreshAction: () -> Void = {
            Task {
                await store.fetch()
            }
        }

        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView(quitAction: quitAction, refreshAction: refreshAction)
                .environmentObject(gameStore)
        )
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
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        gameStore.markAsRead()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
    }
}
