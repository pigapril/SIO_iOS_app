import Foundation

// For /api/market-sentiment
struct MarketSentimentResponse: Codable {
    let compositeScore: Double
    let sentiment: String
    let indicators: [String: Indicator]
}

struct Indicator: Codable {
    let value: Double
    let sentiment: String
}

// For /api/composite-historical-data
struct HistoricalDataItem: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let compositeScore: Double
    let spyClose: Double
}

typealias CompositeHistoricalDataResponse = [HistoricalDataItem] 