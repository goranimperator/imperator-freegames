import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var platforms: [(Platform, [FreeGame])] = []
    @Published var hasUnread = false
    @Published var lastFetched: Date?
    @Published var newGameIds: Set<String> = []
    @Published var isLoading = false

    private let feedURL = "https://www.goranimperator.com/data/free-games.json"
    private let stateURL: URL
    private var seenIds: [String: [String]] = [:]
    private var isInitialFetch: Bool

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Imperator Free Games")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        stateURL = appDir.appendingPathComponent("state.json")
        isInitialFetch = true
        isInitialFetch = !loadState()
    }

    func fetch() async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(feedURL)?t=\(Int(Date().timeIntervalSince1970))") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let feed = try JSONDecoder().decode(FeedResponse.self, from: data)

            var discoveredNewGames: [(Platform, FreeGame)] = []
            var allPlatforms: [(Platform, [FreeGame])] = []

            for platform in Platform.allCases {
                let games = feed.platforms[platform.rawValue] ?? []
                if !games.isEmpty {
                    allPlatforms.append((platform, games))
                }

                let seen = Set(seenIds[platform.rawValue] ?? [])
                for game in games {
                    if !seen.contains(game.id) {
                        discoveredNewGames.append((platform, game))
                        seenIds[platform.rawValue, default: []].append(game.id)
                    }
                }

                if let ids = seenIds[platform.rawValue], ids.count > 50 {
                    seenIds[platform.rawValue] = Array(ids.suffix(50))
                }
            }

            self.platforms = allPlatforms
            self.lastFetched = Date()

            if !isInitialFetch && !discoveredNewGames.isEmpty {
                hasUnread = true
                newGameIds.formUnion(discoveredNewGames.map { $0.1.id })
                NotificationManager.shared.showNotifications(for: discoveredNewGames)
            }

            if isInitialFetch {
                isInitialFetch = false
            }

            saveState()
        } catch {
            // Silently fail, retry next interval
        }
    }

    func markAsRead() {
        hasUnread = false
        newGameIds.removeAll()
    }

    private func loadState() -> Bool {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return false }
        do {
            let data = try Data(contentsOf: stateURL)
            let state = try JSONDecoder().decode(PersistedState.self, from: data)
            seenIds = state.seen
            return true
        } catch {
            return false
        }
    }

    private func saveState() {
        let state = PersistedState(
            seen: seenIds,
            lastFetched: ISO8601DateFormatter().string(from: Date())
        )
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            // Silently fail
        }
    }
}
