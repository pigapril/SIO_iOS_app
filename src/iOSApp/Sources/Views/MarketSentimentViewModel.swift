import SwiftUI
import Combine

@MainActor
class MarketSentimentViewModel: ObservableObject {
    @Published var sentimentData: MarketSentimentResponse?
    @Published var historicalData: [HistoricalDataItem] = []
    @Published var filteredHistoricalData: [HistoricalDataItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: String = "1Y"

    private var cancellables = Set<AnyCancellable>()

    func fetchData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Fetch both data points in parallel
                async let sentiment = APIService.shared.fetchMarketSentiment()
                async let history = APIService.shared.fetchCompositeHistoricalData()
                
                self.sentimentData = try await sentiment
                self.historicalData = try await history
                
                // Initial filter
                filterData(for: selectedTimeRange)

            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "MarketSentimentViewModel")
            }
            self.isLoading = false
        }
    }

    func filterData(for range: String) {
        selectedTimeRange = range
        
        guard !historicalData.isEmpty else {
            filteredHistoricalData = []
            return
        }

        let calendar = Calendar.current
        let endDate = historicalData.last?.date ?? Date()
        var startDate: Date?

        switch range {
        case "1M":
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate)
        case "6M":
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate)
        case "1Y":
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)
        case "3Y":
            startDate = calendar.date(byAdding: .year, value: -3, to: endDate)
        case "All":
            startDate = nil // No start date, show all
        default:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)
        }

        if let start = startDate {
            filteredHistoricalData = historicalData.filter { $0.date >= start }
        } else {
            filteredHistoricalData = historicalData
        }
    }
} 