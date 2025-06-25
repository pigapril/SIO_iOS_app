// src/Sentiment Inside Out/Sentiment Inside Out/StockAppApp.swift
import SwiftUI
import iOSAppSource

@main
struct StockAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared

    var body: some Scene {
        WindowGroup {
            // 将 LaunchView 设为根视图
            // LaunchView 内部会负责在适当的时候展示 MainTabView
            LaunchView()
                // 将 ViewModel 注入环境，供 LaunchView 及其所有子视图（包括 MainTabView）使用
                .environmentObject(authViewModel)
                .environmentObject(toastManager)
        }
    }
}