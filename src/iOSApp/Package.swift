// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "iOSApp",
            targets: ["iOSApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "iOSApp",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                // highlight-start
                // 修正點：我們只宣告 FirebaseAuth，讓它自動帶入需要的 FirebaseCore
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
                // highlight-end
            ]
        ),
    ]
)