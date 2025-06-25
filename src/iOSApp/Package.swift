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
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "iOSAppSource",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                // 明確指定 GoogleSignIn 產品來自 GoogleSignIn-iOS 套件
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                // highlight-start
                // 新增：明確加入 GoogleSignInSwift 產品以使用 SwiftUI 元件
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
                // highlight-end
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)