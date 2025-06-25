// src/iOSApp/Sources/iOSAppSource/Views/LaunchView.swift
import SwiftUI
import iOSAppSource // 導入以使用 AppColors

// 1. 將 struct 宣告為 public，使其能被其他模組看見
public struct LaunchView: View {
    @State private var isActive = false
    private let launchTime = 2.5

    // 2. 當 struct 是 public 時，必須提供一個 public 的初始化方法
    public init() {}

    // 3. body 屬性也必須是 public
    public var body: some View {
        ZStack {
            if isActive {
                MainTabView()
            } else {
                ZStack {
                    // 使用 AppColors 中定義好的顏色，保持一致性
                    AppColors.trend 
                        .ignoresSafeArea()
                    
                    VStack {
                        // Logo 圖片
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                        
                        // App 名稱
                        Text("Sentiment Inside Out")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + launchTime) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
}