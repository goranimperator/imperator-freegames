// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImperatorFreeGames",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ImperatorFreeGames",
            path: "Sources/ImperatorFreeGames"
        )
    ]
)
