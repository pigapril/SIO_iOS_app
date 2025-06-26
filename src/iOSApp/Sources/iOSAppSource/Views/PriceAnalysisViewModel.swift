// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Views/PriceAnalysisViewModel.swift

import SwiftUI
import Combine

@MainActor
class PriceAnalysisViewModel: ObservableObject {
    @Published var stockCode: String
    @Published var years: String
    @Published var backTestDate: Date? = nil
    
    @Published var chartData: PriceAnalysisData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisResult: (price: Double, sentimentKey: String)?
    
    // MARK: - Hot Searches Properties
    @Published var hotSearches: [HotSearchItem] = []
    @Published var isLoadingHotSearches = false
    // MARK: - End Hot Searches Properties
    
    @Published var analysisPeriod: AnalysisPeriod {
        didSet {
            self.years = analysisPeriod.rawValue
        }
    }

    enum AnalysisPeriod: String, CaseIterable {
        case short = "0.5"
        case medium = "1.5"
        case long = "3.5"
    }

    private var cancellables = Set<AnyCancellable>()
    
    init(stockCode: String = "SPY", years: String = "3.5", backTestDate: Date? = nil) {
        self.stockCode = stockCode
        self.years = years
        self.backTestDate = backTestDate
        
        if let period = AnalysisPeriod(rawValue: years) {
            self.analysisPeriod = period
        } else {
            self.analysisPeriod = .long
        }
    }

   func fetchStockData(isManualSearch: Bool = false) {
        isLoading = true
        errorMessage = nil
        analysisResult = nil
        chartData = nil

        Task {
            do {
                let dateString = backTestDate.map {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    return formatter.string(from: $0)
                } ?? ""
                
                // 根據 isManualSearch 決定 source 的值
                let source = isManualSearch ? "manual_price_analysis" : nil
                
                let data = try await APIService.shared.fetchPriceAnalysis(
                    stockCode: stockCode,
                    years: years,
                    backTestDate: dateString,
                    source: source // 將 source 傳遞給 APIService
                )
                self.chartData = data
                calculateAnalysisResult(from: data)
            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "PriceAnalysisView")
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Hot Searches Methods
    /// Fetches the list of hot search items.
    func fetchHotSearches() {
        guard hotSearches.isEmpty else { return } // Avoid re-fetching
        isLoadingHotSearches = true
        Task {
            do {
                let items = try await APIService.shared.fetchHotSearches()
                self.hotSearches = items
            } catch {
                // Silently fail, as the web version appears to do.
                // An empty list will be shown in the UI.
                print("Could not fetch hot searches: \(error.localizedDescription)")
                self.hotSearches = []
            }
            self.isLoadingHotSearches = false
        }
    }
    
    /// Sets the stock code from a hot search item and triggers analysis.
    func performHotSearch(item: HotSearchItem) {
        self.stockCode = item.keyword.uppercased()
        // To maintain consistency with form submission,
        // this immediately triggers a new data fetch.
        fetchStockData(isManualSearch: true)
    }
    // MARK: - End Hot Searches Methods
    
    private func calculateAnalysisResult(from data: PriceAnalysisData) {
        guard let lastPrice = data.prices.last,
              let lastPlus2Sd = data.sdAnalysis.tl_plus_2sd.last,
              let lastPlus1Sd = data.sdAnalysis.tl_plus_sd.last,
              let lastMinus1Sd = data.sdAnalysis.tl_minus_sd.last,
              let lastMinus2Sd = data.sdAnalysis.tl_minus_2sd.last else {
            return
        }
        
        let sentimentKey: String
        if lastPrice >= lastPlus2Sd {
            sentimentKey = "priceAnalysis.sentiment.extremeOptimism"
        } else if lastPrice > lastPlus1Sd {
            sentimentKey = "priceAnalysis.sentiment.optimism"
        } else if lastPrice <= lastMinus2Sd {
            sentimentKey = "priceAnalysis.sentiment.extremePessimism"
        } else if lastPrice < lastMinus1Sd {
            sentimentKey = "priceAnalysis.sentiment.pessimism"
        } else {
            sentimentKey = "priceAnalysis.sentiment.neutral"
        }
        
        self.analysisResult = (price: lastPrice, sentimentKey: sentimentKey)
    }
}