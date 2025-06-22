import SwiftUI
import iOSAppSource

@main
struct StockAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    // Add the shared ToastManager as a StateObject
    @StateObject private var toastManager = ToastManager.shared

    var body: some Scene {
        WindowGroup {
            // 1. 用 ZStack 包裹整個畫面
            ZStack {
                // 2. NavigationView 作為 ZStack 的底層
                NavigationView {
                    MainView()
                }
                .environmentObject(authViewModel)
                .environmentObject(toastManager)

                .onAppear {
                    AppSetupService.configure()
                }
            }
            // 3. 將 .toast 修飾符應用於 ZStack
            // 如此一來，Toast 的 overlay 就會處於最高層級
            .toast(toast: $toastManager.toast)
        }
    }
}