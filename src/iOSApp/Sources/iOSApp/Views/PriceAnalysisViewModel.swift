// In file: pigapril/sio_ios_app/SIO_iOS_app-watchlist/src/iOSApp/Sources/iOSApp/Views/PriceAnalysisViewModel.swift

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
    
    @Published var analysisPeriod: AnalysisPeriod {
        didSet {
            // 當簡易模式的選項改變時，同步更新 years 的值
            self.years = analysisPeriod.rawValue
        }
    }

    enum AnalysisPeriod: String, CaseIterable {
        case short = "0.5"
        case medium = "1.5"
        case long = "3.5"
    }

    private var cancellables = Set<AnyCancellable>()
    
    // ✅ 新增點：自定義初始化方法
    init(stockCode: String = "SPY", years: String = "3.5", backTestDate: Date? = nil) {
        self.stockCode = stockCode
        self.years = years
        self.backTestDate = backTestDate
        
        // 根據傳入的 years 初始化 analysisPeriod
        if let period = AnalysisPeriod(rawValue: years) {
            self.analysisPeriod = period
        } else {
            // 如果 years 不是預設值之一，則預設為長期
            self.analysisPeriod = .long
        }
    }


    func fetchStockData() {
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
                
                let data = try await APIService.shared.fetchPriceAnalysis(
                    stockCode: stockCode,
                    years: years,
                    backTestDate: dateString
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