import SwiftUI
import iOSApp // 這行很重要，確保能讀取到我們套件中的 View

@main
struct StockAppApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
        }
    }
}
