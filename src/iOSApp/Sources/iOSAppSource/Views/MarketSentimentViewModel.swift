// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Views/MarketSentimentViewModel.swift

import SwiftUI
import Combine

// The TimeRangeOption enum is already well-defined for this purpose.
enum TimeRangeOption: String, CaseIterable, Identifiable {
    case oneMonth, threeMonths, sixMonths, oneYear, threeYears, fiveYears, all
    
    var id: String { self.rawValue }
    
    var localizedKey: LocalizedStringKey {
        switch self {
        case .oneMonth: return "timeRangeSelector.month1"
        case .threeMonths: return "timeRangeSelector.month3"
        case .sixMonths: return "timeRangeSelector.month6"
        case .oneYear: return "timeRangeSelector.year1"
        case .threeYears: return "timeRangeSelector.year3"
        case .fiveYears: return "timeRangeSelector.year5"
        case .all: return "timeRangeSelector.all"
        }
    }
}

@MainActor
class MarketSentimentViewModel: ObservableObject {
    @Published var sentimentData: MarketSentimentResponse?
    @Published var historicalData: [HistoricalDataItem] = []
    @Published var filteredHistoricalData: [HistoricalDataItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: TimeRangeOption = .oneYear

    // This will now be bound to the dual-thumb slider and drive the chart's data.
    @Published var dateRange: ClosedRange<Date>? = nil

    // This holds the absolute min/max dates of all available data, used to define the slider's bounds.
    private(set) var fullDateRange: ClosedRange<Date>? = nil
    
    // The single selectedDate property is no longer needed.
    // @Published var selectedDate: Date? = nil

    var compositeSentimentKey: String {
        guard let scoreString = sentimentData?.totalScore, let score = Double(scoreString) else {
            return "sentiment.notAvailable"
        }
        return sentimentKey(for: score)
    }

    private var cancellables = Set<AnyCancellable>()

    func fetchData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let sentiment = APIService.shared.fetchMarketSentiment()
                async let history = APIService.shared.fetchCompositeHistoricalData()
                
                self.sentimentData = try await sentiment
                self.historicalData = try await history
                
                // This new function sets up the date ranges and triggers the initial data filtering.
                setupDateRangeAndInitialFilter()

            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "MarketSentimentViewModel")
            }
            self.isLoading = false
        }
    }

    // New combined setup function to be called once after data fetch.
    private func setupDateRangeAndInitialFilter() {
        guard !historicalData.isEmpty else { return }
        let dates = historicalData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return }
        
        // Set the absolute bounds for the slider.
        self.fullDateRange = minDate...maxDate
        
        // Apply the initial filter based on the default selectedTimeRange (e.g., "1 Year").
        // This will set the initial `dateRange` and populate `filteredHistoricalData`.
        setDateRange(for: self.selectedTimeRange)
    }
    
    // This method is called when the user clicks a button like "1Y", "3Y", etc.
    // It adjusts the `dateRange` which the slider thumbs will then represent.
    func setDateRange(for timeOption: TimeRangeOption) {
        selectedTimeRange = timeOption
        
        guard let fullRange = fullDateRange else { return }
        let calendar = Calendar.current
        let endDate = fullRange.upperBound
        var startDate: Date?

        switch timeOption {
        case .oneMonth: startDate = calendar.date(byAdding: .month, value: -1, to: endDate)
        case .threeMonths: startDate = calendar.date(byAdding: .month, value: -3, to: endDate)
        case .sixMonths: startDate = calendar.date(byAdding: .month, value: -6, to: endDate)
        case .oneYear: startDate = calendar.date(byAdding: .year, value: -1, to: endDate)
        case .threeYears: startDate = calendar.date(byAdding: .year, value: -3, to: endDate)
        case .fiveYears: startDate = calendar.date(byAdding: .year, value: -5, to: endDate)
        case .all: startDate = fullRange.lowerBound
        }
        
        self.dateRange = (startDate ?? fullRange.lowerBound)...endDate
        
        // After setting the range, update the chart's data.
        updateChartData()
    }

    // This method is now called whenever the range slider's value changes.
    func updateChartData() {
        guard let range = dateRange else {
            // If no range is set, show all data.
            filteredHistoricalData = historicalData
            return
        }
        // Filter the historical data to include only items within the selected dateRange.
        filteredHistoricalData = historicalData.filter { range.contains($0.date) }
    }
    
    // MARK: - Unchanged Helper Methods
    
    func sentimentKey(for score: Double?) -> String {
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

    func indicatorKey(forName name: String) -> String? {
        let map = [
            "AAII Bull-Bear Spread": "aaiiSpread",
            "CBOE Put/Call Ratio 5-Day Avg": "cboeRatio",
            "Market Momentum": "marketMomentum",
            "VIX MA50": "vixMA50",
            "Safe Haven Demand": "safeHaven",
            "Junk Bond Spread": "junkBond",
            "S&P 500 COT Index": "cotIndex",
            "NAAIM Exposure Index": "naaimIndex"
        ]
        return map[name]
    }

    func sentimentColor(for sentimentKey: String) -> Color {
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