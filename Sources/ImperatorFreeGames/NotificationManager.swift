import UserNotifications
import AppKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func showNotifications(for newGames: [(Platform, FreeGame)]) {
        guard !newGames.isEmpty else { return }

        if newGames.count <= 3 {
            for (platform, game) in newGames {
                let content = UNMutableNotificationContent()
                content.title = "🎮 Free on \(platform.displayName)"
                content.subtitle = game.regularPrice.map { "\(game.title) (was \($0))" } ?? game.title
                content.body = game.description ?? "Free to claim now"
                content.sound = .default
                content.userInfo = ["url": game.url]

                let request = UNNotificationRequest(
                    identifier: "game-\(game.id)",
                    content: content,
                    trigger: nil
                )
                UNUserNotificationCenter.current().add(request)
            }
        } else {
            let content = UNMutableNotificationContent()
            content.title = "🎮 \(newGames.count) new free games"

            let grouped = Dictionary(grouping: newGames, by: { $0.0 })
            let parts = grouped.map { "\($0.value.count) on \($0.key.displayName)" }
            content.body = parts.joined(separator: ", ")
            content.sound = .default
            content.userInfo = ["url": "https://www.goranimperator.com/free-games"]

            let request = UNNotificationRequest(
                identifier: "games-batch-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
