// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Usaige",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "Usaige",
            path: "Sources/Usaige"
        )
    ]
)
