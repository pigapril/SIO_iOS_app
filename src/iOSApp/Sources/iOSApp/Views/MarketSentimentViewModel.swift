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

    var compositeSentiment: String {
        guard let scoreString = sentimentData?.totalScore, let score = Double(scoreString) else {
            return "中性"
        }
        return sentiment(for: score)
    }

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

    func sentiment(for score: Double) -> String {
        switch score {
        case 0..<20:
            return "極度恐懼"
        case 20..<40:
            return "恐懼"
        case 40..<60:
            return "中性"
        case 60..<80:
            return "貪婪"
        case 80...100:
            return "極度貪婪"
        default:
            return "中性"
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

    func sentimentColor(for sentiment: String) -> Color {
        switch sentiment {
        case "極度恐懼":
            return Color(hex: "#0000FF")
        case "恐懼":
            return Color(hex: "#5B9BD5")
        case "中性":
            return Color(hex: "#708090")
        case "貪婪":
            return Color(hex: "#F0B8CE")
        case "極度貪婪":
            return Color(hex: "#D24A93")
        default:
            return Color.gray
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

// Extension to allow creating Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 