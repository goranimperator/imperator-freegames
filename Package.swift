// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "ImperatorFreeGames",
    // Stays at macOS 13 so the public release keeps working on older systems.
    // The SDK stamp that decides which generation of AppKit controls gets drawn
    // is applied by the Makefile through -Xlinker -platform_version, not here.
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ImperatorFreeGames",
            path: "Sources/ImperatorFreeGames",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
