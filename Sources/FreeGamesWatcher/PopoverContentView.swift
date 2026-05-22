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
    }

    private var headerView: some View {
        HStack {
            if let nsImage = SigilIcon.headerImage() {
                Image(nsImage: nsImage)
            }
            Text("Imperator Free Games")
                .font(.headline)

            Spacer()

            if let date = store.lastFetched {
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HoverButton(action: refreshAction) {
                Image(systemName: store.isLoading ? "ellipsis" : "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .disabled(store.isLoading)
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
                .foregroundStyle(.quaternary)
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
        HStack {
            LaunchAtLoginToggle()

            Spacer()

            HoverButton {
                if let url = URL(string: "https://www.goranimperator.com/free-games") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 5) {
                    if let nsImage = SigilIcon.headerImage(size: 11) {
                        Image(nsImage: nsImage)
                    }
                    Text("Open Website")
                }
                .font(.caption)
            }

            Divider()
                .frame(height: 12)

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
                Image(systemName: platform.iconName)
                    .font(.caption)
                    .foregroundStyle(platformColor)
                Text(platform.displayName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(games.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(Capsule())
            }

            ForEach(games) { game in
                GameRowView(game: game, platform: platform)
            }
        }
    }

    private var platformColor: Color {
        switch platform {
        case .steam: return .blue
        case .epic: return .primary
        case .gog: return .purple
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
                        .background(.blue)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            HStack(spacing: 4) {
                if let price = game.regularPrice {
                    Text("was \(price)")
                        .foregroundStyle(Color(red: 0.85, green: 0.2, blue: 0.2))
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
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
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
        Toggle("Open at Login", isOn: $isEnabled)
            .toggleStyle(.checkbox)
            .font(.caption)
            .foregroundStyle(.primary)
            .opacity(isHovered ? 1.0 : 0.45)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { isHovered = $0 }
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

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
