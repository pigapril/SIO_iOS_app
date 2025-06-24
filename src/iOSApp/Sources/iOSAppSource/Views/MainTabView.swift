// 檔案路徑: /Users/tony.h/tony-stock/iOS App/src/iOSApp/Sources/iOSAppSource/Views/MainTabView.swift

import SwiftUI
import iOSAppSource

public struct MainTabView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared
    @State private var selectedTab: Int = 0

    // --- START: 最終修正 ---
    // 替換為這個新的、更可靠的 packageBundle 屬性
    private var packageBundle: Bundle {
        let bundleName = "iOSApp_iOSAppSource"
        
        // 這是尋找靜態連結 Swift Package 資源包的標準方法
        if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        
        // 如果上述方法失敗，則回退到先前的方法
        return Bundle(for: AuthenticationViewModel.self)
    }
    // --- END: 最終修正 ---
    
    public init() {}

    public var body: some View {
        // ZStack 和 onAppear 的部分保持原樣，不需要修改
        ZStack {
            TabView(selection: $selectedTab) {
                // Tab 的內容完全不需要修改，因為它們已經在使用 packageBundle
                // Dashboard Tab
                NavigationView {
                    DashboardView()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(NSLocalizedString("nav.home", bundle: packageBundle, comment: "Home tab title"))
                }
                .tag(0)

                // Price Analysis Tab
                NavigationView {
                    PriceAnalysisView()
                }
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text(NSLocalizedString("nav.priceAnalysis", bundle: packageBundle, comment: "Price Analysis tab title"))
                }
                .tag(1)

                // Market Sentiment Tab
                NavigationView {
                    MarketSentimentView()
                }
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text(NSLocalizedString("nav.marketSentiment", bundle: packageBundle, comment: "Market Sentiment tab title"))
                }
                .tag(2)

                // Watchlist Tab
                NavigationView {
                    WatchlistView()
                }
                .tabItem {
                    Image(systemName: "list.star")
                    Text(NSLocalizedString("nav.watchlist", bundle: packageBundle, comment: "Watchlist tab title"))
                }
                .tag(3)
            }
            .environmentObject(authViewModel)
            .environmentObject(toastManager)
            .onAppear {
                AppSetupService.configure()
            }
        }
        .toast(toast: $toastManager.toast)
    }
}