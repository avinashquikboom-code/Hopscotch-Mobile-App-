// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-5.6.12"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5+1"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-5.7.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-3.15.2"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-15.2.10"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.3.2"),
        .package(name: "gal", path: "../.packages/gal-2.3.3"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.3.14"),
        .package(name: "printing", path: "../.packages/printing-5.15.0"),
        .package(name: "share_plus", path: "../.packages/share_plus-13.3.0"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.7"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "url_launcher_macos", path: "../.packages/url_launcher_macos-3.2.6"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.11.1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "gal", package: "gal"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "printing", package: "printing"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-macos", package: "url_launcher_macos"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
