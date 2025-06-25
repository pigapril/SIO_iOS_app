// src/iOSApp/Sources/iOSAppSource/Views/LaunchView.swift
import SwiftUI
import iOSAppSource // 導入以使用 AppColors

public struct LaunchView: View {
    @State private var isActive = false
    private let launchTime = 2.5

    public init() {}

    public var body: some View {
        ZStack {
            if isActive {
                MainTabView()
            } else {
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    
                    VStack {
                        // Logo 圖片
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            // --- 修改點: 將 Logo 的框架大小從 150x150 增加到 200x200 ---
                            .frame(width: 250, height: 250) //
                        
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