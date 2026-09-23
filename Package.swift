// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetHUD",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NetHUD", targets: ["NetHUD"])
    ],
    targets: [
        .executableTarget(
            name: "NetHUD",
            path: "NetHUD/Sources"
        )
    ]
)
