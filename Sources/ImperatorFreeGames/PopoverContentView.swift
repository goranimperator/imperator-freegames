import SwiftUI
import ServiceManagement

struct PopoverContentView: View {
    @EnvironmentObject var store: GameStore
    let quitAction: () -> Void
    let refreshAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            gameListView
            Divider()
            footerView
        }
        .frame(width: 340)
        .background(.black.opacity(0.15))
        // Brandbook section 13: window-shaped surfaces are 18pt with a continuous
        // curve on macOS 27. AppKit draws the popover's rounded frame but does not
        // clip the content view to it, so this background paints square corners on
        // top of that frame unless the content is clipped to the same shape.
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var headerView: some View {
        HStack(alignment: .center) {
            if let nsImage = SigilIcon.gamepadImage(size: 16) {
                Image(nsImage: nsImage)
            }
            Text("Imperator FreeGames")
                .font(.headline)

            Spacer()

            if let date = store.lastFetched {
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            RefreshButton(action: refreshAction, isLoading: store.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var gameListView: some View {
        if store.platforms.isEmpty && !store.isLoading {
            emptyStateView
        } else if store.platforms.isEmpty && store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.platforms, id: \.0) { platform, games in
                        PlatformSectionView(platform: platform, games: games)
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 380)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No free games right now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Check back later!")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var footerView: some View {
        HStack(spacing: 14) {
            LaunchAtLoginToggle()

            Spacer()

            HoverButton {
                if let url = URL(string: "https://www.goranimperator.com/free-games") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text("Open Website")
                    .font(.caption)
            }

            HoverButton { AboutPanel.show() } label: {
                Text("About")
                    .font(.caption)
            }

            HoverButton(action: quitAction) {
                Text("Quit")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct PlatformSectionView: View {
    let platform: Platform
    let games: [FreeGame]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(platform.displayName.uppercased())
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(games.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(AppColors.badgeRed)
                    .clipShape(Circle())
            }

            ForEach(games) { game in
                GameRowView(game: game, platform: platform)
            }
        }
    }

}

struct GameRowView: View {
    @EnvironmentObject var store: GameStore
    let game: FreeGame
    let platform: Platform

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(game.title)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)

                if store.newGameIds.contains(game.id) {
                    Text("NEW")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(AppColors.badgeRed)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            HStack(spacing: 4) {
                if let price = game.regularPrice {
                    Text("was \(price)")
                        .foregroundStyle(AppColors.badgeRed)
                }
                if let year = game.year {
                    Text("·").foregroundStyle(.quaternary)
                    Text(String(year))
                        .foregroundStyle(.secondary)
                }
                if let dev = game.developer {
                    Text("·").foregroundStyle(.quaternary)
                    Text(dev)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .font(.caption)

            if let desc = game.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? AppColors.brand.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            if let url = URL(string: game.url) {
                NSWorkspace.shared.open(url)
            }
        }
        .cursor(.pointingHand)
    }
}

struct LaunchAtLoginToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Open at Login")
                .font(.caption)
                .lineLimit(1)
                .fixedSize()
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.55)
                .tint(AppColors.brand)
                .labelsHidden()
        }
        .foregroundStyle(.primary)
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        // Single-argument onChange: the two-argument form the brandbook shows is
        // macOS 14 only, and this app still deploys to 13.
        .onChange(of: isEnabled) { newValue in
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }
}

struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct RefreshButton: View {
    let action: () -> Void
    let isLoading: Bool
    @State private var isHovered = false
    @State private var rotation: Double = 0

    var body: some View {
        Button {
            action()
            withAnimation(.interpolatingSpring(stiffness: 60, damping: 8)) {
                rotation += 360
            }
        } label: {
            if let nsImage = SigilIcon.refreshImage(size: 14) {
                Image(nsImage: nsImage)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .disabled(isLoading)
    }
}

// NSCursor is a stack, so an unmatched push leaves the pushed cursor on screen
// for the whole app. SwiftUI drops the exiting onHover when the view goes away
// under the pointer, which happens here every time the popover closes over a
// hovered row: the pointing hand then survives on top of the footer toggle,
// which is supposed to keep the system arrow. Track our own push and unwind it
// on disappear so the stack always balances.
private struct CursorOnHover: ViewModifier {
    let cursor: NSCursor
    @State private var pushed = false

    func body(content: Content) -> some View {
        content
            .onHover { inside in
                guard inside != pushed else { return }
                pushed = inside
                if inside { cursor.push() } else { NSCursor.pop() }
            }
            .onDisappear {
                guard pushed else { return }
                pushed = false
                NSCursor.pop()
            }
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        modifier(CursorOnHover(cursor: cursor))
    }
}
