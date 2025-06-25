// 檔案路徑: /Users/tony.h/tony-stock/iOS App/src/iOSApp/Sources/iOSAppSource/Views/MainTabView.swift

import SwiftUI
import iOSAppSource

public struct MainTabView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared
    @State private var selectedTab: Int = 0

    private var packageBundle: Bundle {
        let bundleName = "iOSApp_iOSAppSource"
        
        if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        
        return Bundle(for: AuthenticationViewModel.self)
    }
    
    public init() {}

    public var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
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
            // highlight-start
            // 移除此處多餘的 onAppear 設定，因為設定已在 StockAppApp.swift 的 init() 中完成。
            /*
            .onAppear {
                AppSetupService.configure()
            }
            */
            // highlight-end
        }
        .toast(toast: $toastManager.toast)
    }
}