// src/iOSApp/Sources/iOSAppSource/Views/LaunchView.swift
import SwiftUI
import iOSAppSource

public struct LaunchView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    public init() {}

    public var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginWallView()
            }
        }
    }
}

private struct LoginWallView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            // highlight-start
            VStack(spacing: 40) { // 稍微加大整體間距
                
                Spacer() // 這個 Spacer 會將整個內容區塊從螢幕頂部推開一點
                
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                
                // --- 位於 Logo 和文字之間的 Spacer 已被移除 ---

                // 將提示文字和按鈕放在同一個 VStack 中
                VStack(spacing: 20) { // 這個群組使用較小的間距
                    Text("launch.login.prompt", bundle: .module)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    GoogleSignInButtonView(colorScheme: .dark) {
                        Task {
                            await authViewModel.signIn()
                        }
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 40)
                }

                Spacer() // 這個 Spacer 會將整個內容區塊從螢幕底部推開
                Spacer() // 再加一個 Spacer 會把它們向上推得更多
            }
            // highlight-end
        }
    }
}