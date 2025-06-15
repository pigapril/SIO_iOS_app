import SwiftUI
import Combine

@MainActor
class PriceAnalysisViewModel: ObservableObject {
    @Published var stockCode: String = "SPY"
    @Published var years: String = "3.5"
    @Published var backTestDate: Date? = nil
    
    @Published var chartData: PriceAnalysisData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisResult: (price: Double, sentimentKey: String)?
    
    @Published var analysisPeriod: AnalysisPeriod = .long {
        didSet {
            years = analysisPeriod.rawValue
        }
    }

    enum AnalysisPeriod: String, CaseIterable {
        case short = "0.5"
        case medium = "1.5"
        case long = "3.5"
    }

    private var cancellables = Set<AnyCancellable>()

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
