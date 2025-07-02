// src/iOSApp/Sources/iOSAppSource/Views/LaunchView.swift (修改後)

import SwiftUI
import iOSAppSource

public struct LaunchView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // ✨ 步驟 1: 引入付費服務
    @StateObject private var paymentService = PaymentService.shared

    public init() {}

    public var body: some View {
        ZStack {
            // ✨ 步驟 2: 擴展啟動邏輯
            if authViewModel.isLoading || (paymentService.isLoading && PaymentService.isPaywallEnabled) {
                // 當 (正在驗證身份) 或 (付費牆已啟用且正在檢查訂閱狀態) 時，顯示載入畫面
                loadingView
            } else if !authViewModel.isAuthenticated {
                // 如果未登入，顯示登入牆
                LoginWallView()
            } else if PaymentService.isPaywallEnabled && !paymentService.isSubscribed {
                // ✨ 步驟 3: 如果 (付費牆已啟用) 且 (使用者未訂閱)，顯示付費牆
                PaywallView()
            } else {
                // ✨ 步驟 4: 所有檢查通過，顯示 App 主畫面
                // 這種情況包含：
                // 1. 付費牆已啟用且使用者已訂閱
                // 2. 付費牆總開關被關閉
                MainTabView()
            }
        }
        .onAppear {
            // ✨ 步驟 5: 當視圖出現時，觸發狀態檢查
            // App啟動時，authViewModel.restorePreviousSignIn() 會自動被呼叫
            // 如果使用者已登入，我們接著檢查他們的訂閱狀態
            if authViewModel.isAuthenticated {
                paymentService.checkSubscriptionStatus()
            }
        }
        // 當登入狀態改變時 (例如使用者剛登入成功)，也觸發訂閱狀態檢查
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                paymentService.checkSubscriptionStatus()
            }
        }
    }
    
    /// 載入畫面
    private var loadingView: some View {
        VStack(spacing: 20) {
            Image("Logo", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            ProgressView()
        }
    }
}


// LoginWallView 保持不變
private struct LoginWallView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Image("Logo", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                VStack(spacing: 20) {
                    Text("launch.login.prompt".localized())
                        .font(.headline)
                        .foregroundColor(.secondary)
                    SignInWithAppleButtonView(type: .signIn, style: .black) { result in
                        authViewModel.handleAppleSignInResult(result)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 40)
                    GoogleSignInButtonView(colorScheme: .dark) {
                        Task {
                            await authViewModel.signIn()
                        }
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 40)
                }
                Spacer()
                Spacer()
            }
        }
    }
}