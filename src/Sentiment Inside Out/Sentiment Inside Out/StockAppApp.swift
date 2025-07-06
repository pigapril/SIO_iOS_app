// src/Sentiment Inside Out/Sentiment Inside Out/StockAppApp.swift

import SwiftUI
import iOSAppSource
import Firebase

// AppDelegate 用於整合 Firebase 等服務
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase 等 SDK 的初始化
        return true
    }
}


@main
struct StockAppApp: App {
    // 連結 AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // 建立身份驗證、Toast 和新的語言管理器作為環境物件
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var tabSelectionManager = TabSelectionManager.shared // Add this line
    @StateObject private var dashboardViewModel = DashboardViewModel()

    // App 初始化時，執行一次性的設定
    init() {
        AppSetupService.configure()
    }

    var body: some Scene {
        WindowGroup {
    LaunchView()
        .environmentObject(authViewModel)
        .environmentObject(toastManager)
        .environmentObject(languageManager)
        .environmentObject(tabSelectionManager)
        .environmentObject(dashboardViewModel)
        .onOpenURL { url in
            // 處理從 Widget 傳來的 URL
            if url.host == "market-sentiment" {
                // 使用你建立的 TabSelectionManager 來切換分頁
                tabSelectionManager.selectedTab = 2 // 2 是市場情緒分頁的索引
            }
            // 你可以擴充這裡來處理其他 widget 的連結
        }
}
    }
}