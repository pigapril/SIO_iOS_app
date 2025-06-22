// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV1/src/iOSApp/Sources/iOSAppSource/Views/DashboardView.swift
import SwiftUI

/// App 的新主頁，作為一個數據驅動的儀表板。
///
/// 這個視圖遵循 `iOS_rebuild_plan.md` 中 Phase 2 的規劃，整合了多個核心功能的摘要資訊，
/// 為使用者提供一個快速概覽和方便的導航入口。
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var showingMoreView = false
    @State private var quickSearchSymbol: String = ""
    @State private var isAnalysisLinkActive = false

    var body: some View {
        ScrollView {
            // 根據 ViewModel 的狀態顯示載入指示器、錯誤訊息或主內容。
            if viewModel.isLoading && viewModel.marketSentiment == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("common.error", bundle: .module)
                        .font(.headline)
                        .padding(.top)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                // 主內容堆疊
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHeader
                    marketSentimentCard
                    watchlistPreviewCard
                    quickAnalysisCard
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("nav.home", bundle: .module))
        .toolbar {
            // 新增右上角的設定按鈕，用於開啟 "MoreView"
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingMoreView = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingMoreView) {
            // 以 Sheet 形式呈現 MoreView，並為其提供獨立的 NavigationView
            NavigationView {
                MoreView()
                    .navigationBarItems(trailing: Button(NSLocalizedString("common.done", bundle: .module, comment: "Done button")) {
                        showingMoreView = false
                    })
            }
            .environmentObject(authViewModel)
        }
        .onAppear {
            // 僅在初次載入時獲取數據
            if viewModel.marketSentiment == nil {
                viewModel.fetchDashboardData()
            }
        }
    }

    // MARK: - Subviews

    /// 歡迎使用者的標頭
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let user = authViewModel.user {
                // 對已登入使用者顯示個人化問候
                Text(String(format: NSLocalizedString("dashboard.greeting", bundle: .module, comment: "Greeting for a logged in user"), user.username))
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } else {
                // 對未登入使用者顯示通用歡迎訊息
                Text("dashboard.welcome", bundle: .module)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            Text("dashboard.subtitle", bundle: .module)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// 市場情緒卡片
    private var marketSentimentCard: some View {
        NavigationLink(destination: MarketSentimentView()) {
            VStack {
                HStack {
                    Text("dashboard.marketSentimentCard.title", bundle: .module)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                if let sentimentData = viewModel.marketSentiment, let score = Double(sentimentData.totalScore) {
                    let sentimentKey = sentimentKey(for: score)
                    HStack(alignment: .center, spacing: 10) {
                        // 重用 SemiCircleGaugeView 邏輯
                        DashboardGaugeView(value: score, sentimentKey: sentimentKey)
                             .frame(width: 120, height: 100)
                        
                        VStack(alignment: .leading, spacing: 8) {
                             Text(String(format: "%.0f", score))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text(LocalizedStringKey(sentimentKey), bundle: .module)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(sentimentColor(for: sentimentKey))
                        }
                        Spacer()
                    }
                    .padding(.top, 5)
                } else {
                    // 載入中的佔位符
                    ProgressView().frame(height: 100)
                }
            }
            .cardStyle()
        }
    }

    /// 追蹤清單預覽卡片
    private var watchlistPreviewCard: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("dashboard.watchlistCard.title", bundle: .module)
                    .font(.headline)
                Spacer()
                NavigationLink(destination: WatchlistView()) {
                    Text("common.learnMore", bundle: .module)
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // 根據登入狀態和追蹤清單內容顯示不同視圖
            if !authViewModel.isAuthenticated {
                Text("dashboard.watchlistCard.loginPrompt", bundle: .module)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            } else if let firstCategory = viewModel.categories.first, let stocks = firstCategory.stocks, !stocks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 只顯示前 5 支股票作為預覽
                        ForEach(stocks.prefix(5)) { stock in
                            NavigationLink(destination: PriceAnalysisView(initialStockCode: stock.symbol, initialYears: "3.5")) {
                                WatchlistPreviewItem(stock: stock)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("dashboard.watchlistCard.empty", bundle: .module)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    /// 樂活五線譜快速分析卡片
    private var quickAnalysisCard: some View {
        VStack(alignment: .leading) {
            Text("dashboard.quickAnalysisCard.title", bundle: .module).font(.headline)
            
            HStack {
                TextField(NSLocalizedString("dashboard.quickAnalysisCard.placeholder", bundle: .module, comment: "Stock symbol placeholder"), text: $quickSearchSymbol)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                
                // 使用 isAnalysisLinkActive 狀態來觸發導航
                Button(action: {
                    if !quickSearchSymbol.isEmpty {
                        isAnalysisLinkActive = true
                    }
                }) {
                    Text("dashboard.quickAnalysisCard.button", bundle: .module)
                }
                .buttonStyle(.borderedProminent)
                .disabled(quickSearchSymbol.isEmpty)
            }
            
            // 這個 NavigationLink 是隱藏的，由按鈕的狀態來啟動
            NavigationLink(
                destination: PriceAnalysisView(initialStockCode: quickSearchSymbol, initialYears: "3.5"),
                isActive: $isAnalysisLinkActive
            ) { EmptyView() }
        }
        .cardStyle()
    }

    // MARK: - Helper Functions & Sub-components

    /// 根據分數返回對應的情緒本地化鍵
    private func sentimentKey(for score: Double?) -> String {
        guard let score = score else { return "sentiment.notAvailable" }
        switch score {
        case 0..<20: return "sentiment.extremeFear"
        case 20..<40: return "sentiment.fear"
        case 40..<60: return "sentiment.neutral"
        case 60..<80: return "sentiment.greed"
        case 80...100: return "sentiment.extremeGreed"
        default: return "sentiment.neutral"
        }
    }
    
    /// 根據情緒鍵返回對應的顏色
    private func sentimentColor(for sentimentKey: String) -> Color {
        switch sentimentKey {
        case "sentiment.extremeFear": return Color(hex: 0x0000FF)
        case "sentiment.fear": return Color(hex: 0x5B9BD5)
        case "sentiment.neutral": return Color(hex: 0x708090)
        case "sentiment.greed": return Color(hex: 0xF0B8CE)
        case "sentiment.extremeGreed": return Color(hex: 0xD24A93)
        default: return Color.gray
        }
    }
}

// MARK: - Reusable View Modifiers and Components

/// 卡片樣式修飾符
struct DashboardCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(DashboardCardModifier())
    }
}

/// 儀表板專用的儀表盤視圖 (簡化版)
private struct DashboardGaugeView: View {
    let value: Double
    let sentimentKey: String
    
    private var sentimentGradient: AngularGradient {
        // ... (與 MarketSentimentView 中相同的漸層色邏輯)
        let colors = [
            Color(hex: 0x0000FF), // Extreme Fear
            Color(hex: 0x5B9BD5), // Fear
            Color(hex: 0x708090), // Neutral
            Color(hex: 0xF0B8CE), // Greed
            Color(hex: 0xD24A93)  // Extreme Greed
        ]
        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .bottom,
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(Color(.systemGray5), lineWidth: 12)
                
            Circle()
                .trim(from: 0.5, to: 0.5 + (value / 100.0) / 2.0)
                .stroke(sentimentGradient, lineWidth: 12)

            Circle()
                .fill(Color(hex: 0x708090))
                .frame(width: 8, height: 8)
                .offset(y: -6)
                .rotationEffect(.degrees(-90 + (value / 100.0) * 180.0))
        }
        .animation(.spring(), value: value)
    }
}

/// 追蹤清單預覽中的單個股票項目
private struct WatchlistPreviewItem: View {
    let stock: Stock

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(stock.symbol)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 重用 PriceSentimentGauge 邏輯來顯示情緒
            if stock.analysis != nil {
                PriceSentimentGauge(stock: stock)
                    .frame(height: 18)
            } else {
                 Text("...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, height: 70)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


/// 從 WatchlistView 複製過來的價格情緒儀表
private struct PriceSentimentGauge: View {
    let stock: Stock

    private var percentage: Double {
        guard let analysis = stock.analysis else { return 0.5 }
        let support = analysis.tl_minus_2sd
        let resistance = analysis.tl_plus_2sd
        guard resistance > support else { return 0.5 }
        let value = (stock.price - support) / (resistance - support)
        return max(0, min(1, value))
    }
    
    private var sentimentKey: String {
        guard let analysis = stock.analysis else { return "priceAnalysis.sentiment.neutral" }
        if stock.price >= analysis.tl_plus_2sd { return "priceAnalysis.sentiment.extremeOptimism" }
        if stock.price > analysis.tl_plus_sd { return "priceAnalysis.sentiment.optimism" }
        if stock.price <= analysis.tl_minus_2sd { return "priceAnalysis.sentiment.extremePessimism" }
        if stock.price < analysis.tl_minus_sd { return "priceAnalysis.sentiment.pessimism" }
        return "priceAnalysis.sentiment.neutral"
    }

    private var sentimentColor: Color {
        switch sentimentKey {
            case "priceAnalysis.sentiment.extremeOptimism": return AppColors.plus2SD
            case "priceAnalysis.sentiment.optimism": return AppColors.plus1SD
            case "priceAnalysis.sentiment.pessimism": return AppColors.minus1SD
            case "priceAnalysis.sentiment.extremePessimism": return AppColors.minus2SD
            default: return AppColors.trend
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(LocalizedStringKey(sentimentKey), bundle: .module)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(sentimentColor)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray4))
                    Capsule().fill(sentimentColor.opacity(0.8)).frame(width: geometry.size.width * CGFloat(percentage))
                }
            }
            .frame(height: 6)
        }
    }
}