import SwiftUI
import GoogleSignIn // 只需導入核心模組

/// 使用 UIViewRepresentable 包裝 UIKit 的 GIDSignInButton，使其可以在 SwiftUI 中使用。
/// 這樣做比直接使用 GoogleSignInSwift 更穩定，可以避免模組找不到的問題。
struct GoogleSignInButtonView: UIViewRepresentable {
    
    // 設置按鈕的顏色主題
    var colorScheme: GIDSignInButtonColorScheme = .dark
    
    // 按鈕被點擊時要執行的動作
    var action: () -> Void

    // 創建 UIKit 視圖
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.colorScheme = self.colorScheme
        button.style = .wide
        
        // 將按鈕的點擊事件連接到我們的 Coordinator
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.onTap),
            for: .touchUpInside
        )
        
        return button
    }

    // 更新視圖（在此案例中不需要）
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {
        uiView.colorScheme = self.colorScheme
    }

    // 創建 Coordinator，作為 UIKit 和 SwiftUI 之間的橋樑
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    // Coordinator 類別，用於處理來自 UIKit 的回調
    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func onTap() {
            action()
        }
    }
}