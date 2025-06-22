// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV1/src/iOSApp/Sources/iOSAppSource/Views/MainTabView.swift
import SwiftUI
import iOSAppSource

// MainTabView 將作為 App 的新根視圖，取代舊的 MainView。
// 它使用 TabView 來建立一個現代化的、符合 iOS 設計標準的主導航介面。
public struct MainTabView: View {
    // 透過 @StateObject 管理 AuthenticationViewModel，確保其生命週期與視圖一致。
    @StateObject private var authViewModel = AuthenticationViewModel()
    // 透過 @StateObject 管理 ToastManager，使其在整個 App 中共享。
    @StateObject private var toastManager = ToastManager.shared

    // 用於追蹤當前選擇的 Tab，方便進行程式化切換。
    @State private var selectedTab: Int = 0

    /// 公開的初始化方法，允許從其他模組（例如主 App Target）創建此視圖。
    public init() {}

    public var body: some View {
        // ZStack 用於將 Toast 訊息浮動在所有視圖之上。
        ZStack {
            // TabView 是 App 的核心導航結構。
            TabView(selection: $selectedTab) {
                // 儀表板 Tab (新的首頁)
                // 每個 Tab 都包裹在 NavigationView 中，以提供獨立的導航堆疊。
                NavigationView {
                    // *** FIX: 將 HomeView() 更換為新的 DashboardView() ***
                    DashboardView()
                }
                .tabItem {
                    // 設定 Tab 的圖示和標籤文字，使用本地化字串。
                    Label(LocalizedStringKey("nav.home"), systemImage: "house.fill")
                }
                .tag(0)

                // 價格分析 Tab
                NavigationView {
                    PriceAnalysisView()
                }
                .tabItem {
                    Label(LocalizedStringKey("nav.priceAnalysis"), systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

                // 市場情緒 Tab
                NavigationView {
                    MarketSentimentView()
                }
                .tabItem {
                    Label(LocalizedStringKey("nav.marketSentiment"), systemImage: "heart.fill")
                }
                .tag(2)

                // 追蹤清單 Tab
                NavigationView {
                    WatchlistView()
                }
                .tabItem {
                    Label(LocalizedStringKey("nav.watchlist"), systemImage: "list.star")
                }
                .tag(3)
            }
            // 將 ViewModel 和 ToastManager 注入到環境中，讓所有子視圖都能存取。
            .environmentObject(authViewModel)
            .environmentObject(toastManager)
            .onAppear {
                // 在 App 啟動時執行必要的設定。
                AppSetupService.configure()
            }
        }
        // 將 Toast 修飾符應用於最外層的 ZStack，確保 Toast 能覆蓋在 TabView 之上。
        .toast(toast: $toastManager.toast)
    }
}