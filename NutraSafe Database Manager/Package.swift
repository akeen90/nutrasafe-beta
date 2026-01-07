// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NutraSafeDatabaseManager",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "NutraSafeDatabaseManager",
            path: "Sources"
        )
    ]
)
