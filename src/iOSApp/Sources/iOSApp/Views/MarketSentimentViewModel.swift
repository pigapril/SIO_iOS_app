import SwiftUI
import Combine

// 新增：用於時間範圍選擇的 Enum，包含翻譯鍵
enum TimeRangeOption: String, CaseIterable, Identifiable {
    case oneMonth, threeMonths, sixMonths, oneYear, threeYears, fiveYears, all
    
    var id: String { self.rawValue }
    
    // 返回對應的翻譯鍵
    var localizedKey: LocalizedStringKey {
        switch self {
        case .oneMonth: return "timeRangeSelector.month1"
        case .threeMonths: return "timeRangeSelector.month3"
        case .sixMonths: return "timeRangeSelector.month6"
        case .oneYear: return "timeRangeSelector.year1"
        case .threeYears: return "timeRangeSelector.year3"
        case .fiveYears: return "timeRangeSelector.year5"
        case .all: return "timeRangeSelector.all" // 假設你在 translation.json 中新增了 "all": "全部"
        }
    }
    
    // 返回 API 需要的字串值
    var stringValue: String {
        switch self {
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .threeYears: return "3Y"
        case .fiveYears: return "5Y"
        case .all: return "All"
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
    // 修改：使用新的 Enum 來管理狀態
    @Published var selectedTimeRange: TimeRangeOption = .oneYear
    @Published var dateRange: ClosedRange<Date>? = nil
    @Published var selectedDate: Date? = nil

    private var fullDateRange: ClosedRange<Date>? = nil

    // 修改：回傳翻譯鍵
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
                
                setupDateRange()
                filterData(for: selectedTimeRange)

            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "MarketSentimentViewModel")
            }
            self.isLoading = false
        }
    }

    func setupDateRange() {
        guard !historicalData.isEmpty else { return }
        let dates = historicalData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return }
        self.fullDateRange = minDate...maxDate
        self.dateRange = minDate...maxDate
        self.selectedDate = maxDate
    }

    // 修改：回傳翻譯鍵
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
        // ✅ **修正點：將顏色字串改為十六進位數字**
        switch sentimentKey {
        case "sentiment.extremeFear": return Color(hex: 0x0000FF)
        case "sentiment.fear": return Color(hex: 0x5B9BD5)
        case "sentiment.neutral": return Color(hex: 0x708090)
        case "sentiment.greed": return Color(hex: 0xF0B8CE)
        case "sentiment.extremeGreed": return Color(hex: 0xD24A93)
        default: return Color.gray
        }
    }

    func filterData(for range: TimeRangeOption) {
        selectedTimeRange = range
        
        guard !historicalData.isEmpty else {
            filteredHistoricalData = []
            return
        }

        let calendar = Calendar.current
        let endDate = historicalData.last?.date ?? Date()
        var startDate: Date?

        switch range {
        case .oneMonth: startDate = calendar.date(byAdding: .month, value: -1, to: endDate)
        case .threeMonths: startDate = calendar.date(byAdding: .month, value: -3, to: endDate)
        case .sixMonths: startDate = calendar.date(byAdding: .month, value: -6, to: endDate)
        case .oneYear: startDate = calendar.date(byAdding: .year, value: -1, to: endDate)
        case .threeYears: startDate = calendar.date(byAdding: .year, value: -3, to: endDate)
        case .fiveYears: startDate = calendar.date(byAdding: .year, value: -5, to: endDate)
        case .all: startDate = nil
        }

        let newFilteredData: [HistoricalDataItem]
        if let start = startDate {
            newFilteredData = historicalData.filter { $0.date >= start }
        } else {
            newFilteredData = historicalData
        }

        if let firstDate = newFilteredData.first?.date, let lastDate = newFilteredData.last?.date {
            self.dateRange = firstDate...lastDate
            if selectedDate == nil || !(dateRange?.contains(selectedDate!) ?? false) {
                 self.selectedDate = lastDate
            }
        }
        
        filterDataBySlider()
    }

    func filterDataBySlider() {
        guard let range = dateRange, let selected = selectedDate else {
            if filteredHistoricalData.isEmpty {
                 filteredHistoricalData = historicalData
            }
            return
        }
        
        let sliderFilteredData = historicalData.filter { range.contains($0.date) }
        filteredHistoricalData = sliderFilteredData.filter { $0.date <= selected }
    }
}
