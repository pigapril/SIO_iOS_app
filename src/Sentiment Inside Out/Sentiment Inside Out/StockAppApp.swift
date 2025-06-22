import SwiftUI
import iOSAppSource

@main
struct StockAppApp: App {
    // 根據計畫，由 App 層級持有 StateObject，作為唯一的資料來源。
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared

    var body: some Scene {
        WindowGroup {
            // 將 MainTabView 設為新的根視圖。
            // MainTabView 內部已包含 Tab、Navigation、ZStack 和 Toast 功能。
            MainTabView()
                // 將 ViewModel 注入環境，供 MainTabView 及其所有子視圖使用。
                .environmentObject(authViewModel)
                .environmentObject(toastManager)
        }
    }
}