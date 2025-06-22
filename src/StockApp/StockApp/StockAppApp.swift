import SwiftUI
import iOSAppSource

@main
struct StockAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    // Add the shared ToastManager as a StateObject
    @StateObject private var toastManager = ToastManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
            .environmentObject(authViewModel)
            // Apply the toast modifier to the root view
            .toast(toast: $toastManager.toast)
            .onAppear {
                AppSetupService.configure()
            }
        }
    }
}