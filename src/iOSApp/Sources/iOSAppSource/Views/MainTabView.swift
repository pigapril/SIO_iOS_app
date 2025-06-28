// src/iOSApp/Sources/iOSAppSource/Views/MainTabView.swift

import SwiftUI
import iOSAppSource

public struct MainTabView: View {
    // 從環境中接收共享的 ViewModel 和服務，而不是在本地創建新的實例
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var languageManager: LanguageManager

    // 用於控制當前選中分頁的狀態
    @State private var selectedTab: Int = 0
    
    public init() {}

    public var body: some View {
        // ZStack 讓我們可以將 Toast 視圖疊加在 TabView 之上
        ZStack {
            TabView(selection: $selectedTab) {
                // 首頁 (儀表板) 分頁
                NavigationView {
                    DashboardView()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    // 修改後：使用 .localized() 方法
                    Text("nav.home".localized())
                }
                .tag(0)

                // 價格分析分頁
                NavigationView {
                    PriceAnalysisView()
                }
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    // 修改後：使用 .localized() 方法
                    Text("nav.priceAnalysis".localized())
                }
                .tag(1)

                // 市場情緒分頁
                NavigationView {
                    MarketSentimentView()
                }
                .tabItem {
                    Image(systemName: "heart.fill")
                    // 修改後：使用 .localized() 方法
                    Text("nav.marketSentiment".localized())
                }
                .tag(2)

                // 追蹤清單分頁
                NavigationView {
                    WatchlistView()
                }
                .tabItem {
                    Image(systemName: "list.star")
                    // 修改後：使用 .localized() 方法
                    Text("nav.watchlist".localized())
                }
                .tag(3)
            }
            // 環境物件會自動向下傳遞給 TabView 內的所有子視圖，
            // 因此不再需要在這裡單獨注入 authViewModel 和 toastManager。
        }
        // 將 Toast 視圖修飾符應用於 ZStack，使其能顯示在所有內容之上
        .toast(toast: $toastManager.toast)
    }
}