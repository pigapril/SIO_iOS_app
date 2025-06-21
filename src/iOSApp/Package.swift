// swift-tools-version:5.9
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
            targets: ["iOSAppSource"]
        ),
    ],
    dependencies: [
        // highlight-start
        // 重新加回 GoogleSignIn-iOS 套件
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
        // highlight-end
    ],
    targets: [
        .target(
            name: "iOSAppSource",
            dependencies: [
                // highlight-start
                // 明確指定 FirebaseAuth 產品來自 firebase-ios-sdk 套件
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                // 明確指定 GoogleSignIn 產品來自 GoogleSignIn-iOS 套件
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
                // highlight-end
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)