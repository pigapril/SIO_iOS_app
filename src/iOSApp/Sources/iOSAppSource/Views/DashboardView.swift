// pigapril/sio_ios_app/SIO_iOS_app-language-setting/src/iOSApp/Sources/iOSAppSource/Views/DashboardView.swift
import SwiftUI

/// App 的主頁，作為一個數據驅動的儀表板。
///
/// 這個視圖現在直接使用從後端獲取並預先排序好的追蹤清單預覽資料，
/// 以達到最佳的載入效能和使用者體驗。
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var tabSelectionManager: TabSelectionManager // Add this line
    
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
                    Text("common.error".localized())
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
                VStack(alignment: .leading, spacing: 20) {
                    marketSentimentCard
                    watchlistPreviewCard
                    quickAnalysisCard
                }
                .padding(.vertical)
           }
        }
        .refreshable {
            // This block will be executed when the user pulls to refresh.
            // It directly calls our data fetching function.
            await viewModel.fetchDashboardData()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(
            Text(
                authViewModel.user != nil ?
                String(format: "dashboard.greeting".localized(), authViewModel.user!.username) :
                "dashboard.welcome".localized()
            )
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingMoreView = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingMoreView) {
            NavigationView {
                MoreView()
                    .navigationBarItems(trailing: Button("common.done".localized()) {
                        showingMoreView = false
                    })
            }
            .environmentObject(authViewModel)
        }
        .onAppear {
            // 現在 fetchDashboardData 會獲取所有儀表板需要的輕量級資料
            if viewModel.marketSentiment == nil {
                viewModel.fetchDashboardData()
            }
        }
    }

    // MARK: - Subviews

    /// 市場情緒卡片
    private var marketSentimentCard: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("dashboard.marketSentimentCard.title".localized())
                    .font(.headline)
                Spacer()
                // Change NavigationLink to Button for tab switching
                Button(action: {
                    tabSelectionManager.selectedTab = 2 // Tab index for Market Sentiment
                }) {
                    HStack {
                        Text("common.learnMore".localized())
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(PlainButtonStyle()) // Remove default button styling if desired
            }
            
            if let sentimentData = viewModel.marketSentiment, let score = Double(sentimentData.totalScore) {
                let sentimentKey = sentimentKey(for: score)
                HStack(alignment: .center,) {
                        SemiCircleGaugeView(value: score, showLabels: false)
                            .frame(width: 130, height: 90)
                            .offset(y: -10)
                        
                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                             Text("dashboard.marketSentimentCard.currentSentiment".localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                             Text(sentimentKey.localized())
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundColor(sentimentColor(for: sentimentKey))
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 10)
                } else {
                    ProgressView().frame(height: 120, alignment: .center)
                }
            }
            .cardStyle()
    }

    /// 追蹤清單預覽卡片
    private var watchlistPreviewCard: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("dashboard.watchlistCard.title".localized())
                    .font(.headline)
                Spacer()
                // Change NavigationLink to Button for tab switching
                Button(action: {
                    tabSelectionManager.selectedTab = 3 // Tab index for Watchlist
                }) {
                    HStack {
                        Text("common.learnMore".localized())
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(PlainButtonStyle()) // Remove default button styling if desired
            }
            
            if !authViewModel.isAuthenticated {
                VStack {
                    Text("dashboard.watchlistCard.loginPrompt".localized())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button(action: {
                        Task { await authViewModel.signIn() }
                    }) {
                        Text("userActions.login".localized())
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            
            } else if !viewModel.prioritizedWatchlistPreview.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.prioritizedWatchlistPreview) { stock in
                            NavigationLink(destination: PriceAnalysisView(initialStockCode: stock.symbol, initialYears: "3.5")) {
                                WatchlistPreviewItem(stock: stock)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("dashboard.watchlistCard.empty".localized())
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    /// 樂活五線譜快速分析卡片 (No change for this card's NavigationLink)
    private var quickAnalysisCard: some View {
        VStack(alignment: .leading) {
            Text("dashboard.quickAnalysisCard.title".localized()).font(.headline)
            
            HStack {
                TextField("dashboard.quickAnalysisCard.placeholder".localized(), text: $quickSearchSymbol)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                
                Button(action: {
                    if !quickSearchSymbol.isEmpty {
                        isAnalysisLinkActive = true
                    }
                }) {
                    Text("dashboard.quickAnalysisCard.button".localized())
                }
                .buttonStyle(.borderedProminent)
                .disabled(quickSearchSymbol.isEmpty)
            }
            
            NavigationLink(
                destination: PriceAnalysisView(initialStockCode: quickSearchSymbol, initialYears: "3.5"),
                isActive: $isAnalysisLinkActive
            ) { EmptyView() }
        }
        .cardStyle()
    }

    // MARK: - Helper Functions & Sub-components (無需修改)

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
    
    private func sentimentColor(for sentimentKey: String) -> Color {
        switch sentimentKey {
        case "sentiment.extremeFear": return AppColors.minus2SD
        case "sentiment.fear": return AppColors.minus1SD
        case "sentiment.neutral": return AppColors.trend
        case "sentiment.greed": return AppColors.plus1SD
        case "sentiment.extremeGreed": return AppColors.plus2SD
        default: return Color.gray
        }
    }
}


// MARK: - Reusable Components (無需修改)

/// 追蹤清單預覽中的單個股票項目
private struct WatchlistPreviewItem: View {
    let stock: Stock

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            StockLogoView(stock: stock, size: 32)

            Text(stock.symbol)
                .font(.headline)
                .foregroundColor(.primary)
            
            if stock.analysis != nil {
                DashboardPriceSentimentGauge(stock: stock)
                    .frame(height: 18)
            } else {
                 Text("...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, height: 100)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}


/// 儀表板版本的價格情緒儀表
private struct DashboardPriceSentimentGauge: View {
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
            Text(sentimentKey.localized())
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