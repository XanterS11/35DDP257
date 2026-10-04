// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "35DDP257",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "35DDP257Core",
            targets: ["35DDP257Core"]
        ),
    ],
    dependencies: [
        // Tamamen yerel Swift, AVFoundation, MediaPlayer, LocalAuthentication ve CarPlay framework'leri kullanılır.
    ],
    targets: [
        .target(
            name: "35DDP257Core",
            dependencies: [],
            path: ".",
            exclude: [
                "README.md",
                "35DDP257.entitlements",
                "App/Info.plist"
            ],
            sources: [
                "App",
                "Authentication",
                "DJEngine",
                "Library",
                "Spotify",
                "Views",
                "CarPlay",
                "Utilities"
            ]
        )
    ]
)
