import AppKit
import SwiftUI

@MainActor
final class AboutPanel {
    private static var panel: NSPanel?

    static func show() {
        if let existing = panel, existing.isVisible {
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
        panel.center()

        panel.contentViewController = NSHostingController(
            rootView: AboutView()
        )

        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }
}

struct AboutView: View {
    @State private var isLinkHovered = false

    var body: some View {
        VStack(spacing: 12) {
            if let nsImage = SigilIcon.headerImage(size: 64) {
                Image(nsImage: nsImage)
                    .interpolation(.high)
            }

            Text("Imperator Free Games")
                .font(.headline)

            Text("Version 1.0.0 (Build 1)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("© 2024-2026 Goran Imperator")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text("goranimperator.com")
                .font(.caption)
                .foregroundStyle(AppColors.brand)
                .underline(isLinkHovered)
                .onHover { isLinkHovered = $0 }
                .cursor(.pointingHand)
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
