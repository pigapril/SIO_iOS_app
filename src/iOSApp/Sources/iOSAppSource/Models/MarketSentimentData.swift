import Foundation

// For /api/market-sentiment
struct MarketSentimentResponse: Codable {
    let totalScore: String
    let lastUpdated: Date
    let compositeScoreLastUpdate: Date
    let indicators: [String: Indicator]
}

struct Indicator: Codable {
    let date: Date
    let value: Double
    let weightedScore: Double
    let contribution: Double
    let percentileRank: Double
}

// For /api/composite-historical-data
struct HistoricalDataItem: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let compositeScore: Double
    let spyClose: Double
}

typealias CompositeHistoricalDataResponse = [HistoricalDataItem]

// For /api/indicator-history
struct IndicatorHistoricalDataItem: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let value: Double
    let percentileRank: Double?
} 