import AppKit
import SwiftUI

@MainActor
final class AboutPanel {
    private static var panel: NSPanel?

    static func show() {
        if let existing = panel, existing.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 260),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        // An NSPanel hides itself when its app deactivates, and this app is an
        // .accessory that goes inactive the moment anything else is clicked.
        // Left at the default the panel vanishes behind the first click outside
        // it and the user has to reopen it from a popover they also just closed.
        panel.hidesOnDeactivate = false
        // The app forces dark mode on NSApp, but a panel created later does not
        // inherit that, so state it here too.
        panel.appearance = NSAppearance(named: .darkAqua)

        panel.contentViewController = NSHostingController(
            rootView: AboutView()
        )

        // Setting contentViewController resizes the window to the hosted view's
        // fitting size, and a SwiftUI view that has not laid out yet reports
        // zero, so the contentRect above is thrown away. Force the layout and
        // state the size, or center() below runs against a 0x0 frame and parks
        // the panel's left edge on the screen's centre line instead of its
        // middle. Measured before this: a 300x292 panel landed at x=840 on a
        // 1680pt screen, where centred is x=690.
        if let hosted = panel.contentViewController?.view {
            hosted.layoutSubtreeIfNeeded()
            panel.setContentSize(NSSize(width: 300, height: max(260, hosted.fittingSize.height)))
        } else {
            panel.setContentSize(NSSize(width: 300, height: 260))
        }

        // After the size is settled, never before.
        panel.center()

        // Ordering front is not enough from an .accessory app: without the
        // activation the panel comes up behind whatever the user was in.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }
}

struct AboutView: View {
    @State private var isLinkHovered = false

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Version \(v) (Build \(b))"
    }

    private var copyright: String {
        let year = Calendar.current.component(.year, from: Date())
        return "© 1986-\(year) Goran Imperator"
    }

    var body: some View {
        VStack(spacing: 12) {
            if let nsImage = SigilIcon.headerImage(size: 64) {
                Image(nsImage: nsImage)
                    .interpolation(.high)
            }

            Text("Imperator FreeGames")
                .font(.headline)

            Text(version)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(copyright)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text("goranimperator.com")
                .font(.caption)
                .foregroundStyle(AppColors.brand)
                .underline(isLinkHovered)
                .onHover { isLinkHovered = $0 }
                .onTapGesture {
                    if let url = URL(string: "https://www.goranimperator.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
        }
        .padding(24)
        .frame(width: 300, height: 260)
    }
}
