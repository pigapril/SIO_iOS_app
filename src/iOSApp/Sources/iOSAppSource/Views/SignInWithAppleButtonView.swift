//  SignInWithAppleButtonView.swift

import SwiftUI
import AuthenticationServices // 匯入驗證服務框架

/// 封裝 UIKit 的 ASAuthorizationAppleIDButton 以在 SwiftUI 中使用
struct SignInWithAppleButtonView: UIViewRepresentable {
    
    // 定義按鈕的外觀
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    // 處理完成後的回調
    var onCompletion: (Result<ASAuthorization, Error>) -> Void

    // 創建 UIKit 視圖
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleButtonPress),
            for: .touchUpInside
        )
        return button
    }

    // 更新視圖 (此處不需要)
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    // 創建協調器 (Coordinator)
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 協調器類別，用於處理來自 UIKit 的回調並遵守 Apple 登入的代理協定
    class Coordinator: NSObject, ASAuthorizationControllerDelegate {
        var parent: SignInWithAppleButtonView

        init(_ parent: SignInWithAppleButtonView) {
            self.parent = parent
        }

        @objc func handleButtonPress() {
            // 建立一個 Apple ID 登入請求
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            // 請求獲取用戶的全名和 Email
            request.requestedScopes = [.fullName, .email]

            // 建立一個授權控制器來管理請求
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            // 執行授權流程
            authorizationController.performRequests()
        }
        
        // 授權成功時的回調
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }
        
        // 授權失敗時的回調
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }
    }
}