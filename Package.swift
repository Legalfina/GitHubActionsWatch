// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitHubActionsWatch",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "GitHubActionsWatch",
            path: "Sources/GitHubActionsBar"
        )
    ]
)
