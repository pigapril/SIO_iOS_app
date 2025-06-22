import SwiftUI
import iOSAppSource // 導入我們自己的套件

@main
struct StockAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
            .environmentObject(authViewModel)
            .onAppear {
                // 在 App 視圖出現時，執行一次性的設定
                AppSetupService.configure()
            }
        }
    }
}