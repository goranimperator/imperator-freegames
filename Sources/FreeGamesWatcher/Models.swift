import Foundation

struct FeedResponse: Codable {
    let updatedAt: String
    let platforms: [String: [FreeGame]]
}

struct FreeGame: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let year: Int?
    let developer: String?
    let url: String
    let regularPrice: String?
    let addedAt: String?
}

enum Platform: String, CaseIterable {
    case steam, epic, gog

    var displayName: String {
        switch self {
        case .steam: return "Steam"
        case .epic: return "Epic Games"
        case .gog: return "GOG"
        }
    }

    var iconName: String {
        switch self {
        case .steam: return "s.circle.fill"
        case .epic: return "e.circle.fill"
        case .gog: return "g.circle.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .steam: return "steam"
        case .epic: return "epic"
        case .gog: return "gog"
        }
    }
}

struct PersistedState: Codable {
    var seen: [String: [String]]
    var lastFetched: String?
}
