// MODIFIED: Complete replacement for StockAppApp.swift

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
    @StateObject private var tabSelectionManager = TabSelectionManager.shared
    @StateObject private var dashboardViewModel = DashboardViewModel()

    // App 初始化時，執行一次性的設定
    init() {
        // MODIFICATION: Wrap the call to the throwing function in a do-catch block.
        do {
            try AppSetupService.configure()
        } catch {
            // If configuration fails, the app cannot run correctly.
            // In a real app, you might want to set a global error state
            // to show a persistent error message to the user.
            // For now, we will print a detailed error to the console.
            print("==================================================")
            print("APP CONFIGURATION FAILED. THE APP WILL NOT WORK.")
            print("Error: \(error.localizedDescription)")
            print("==================================================")
            // Note: The UI might show an error or be non-functional,
            // but it will no longer crash with a fatalError.
        }
    }

    var body: some Scene {
        WindowGroup {
            LaunchView()
                // 將所有需要的服務注入到 SwiftUI 環境中
                .environmentObject(authViewModel)
                .environmentObject(toastManager)
                .environmentObject(languageManager)
                .environmentObject(tabSelectionManager)
                .environmentObject(dashboardViewModel)

        }
    }
}