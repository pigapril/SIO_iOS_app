// src/iOSApp/Sources/iOSAppSource/Models/MarketSentimentData.swift

import Foundation

// MARK: - Market Sentiment Response
public struct MarketSentimentResponse: Codable {
    public let totalScore: String
    public let lastUpdated: Date
    public let compositeScoreLastUpdate: Date
    public let indicators: [String: Indicator]

    public init(totalScore: String, lastUpdated: Date, compositeScoreLastUpdate: Date, indicators: [String: Indicator]) {
        self.totalScore = totalScore
        self.lastUpdated = lastUpdated
        self.compositeScoreLastUpdate = compositeScoreLastUpdate
        self.indicators = indicators
    }
}

// MARK: - Indicator
public struct Indicator: Codable {
    public let date: Date
    public let value: Double
    public let weightedScore: Double
    public let contribution: Double
    public let percentileRank: Double

    public init(date: Date, value: Double, weightedScore: Double, contribution: Double, percentileRank: Double) {
        self.date = date
        self.value = value
        self.weightedScore = weightedScore
        self.contribution = contribution
        self.percentileRank = percentileRank
    }
}

// MARK: - Composite Historical Data
public struct HistoricalDataItem: Codable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let compositeScore: Double
    public let spyClose: Double

    public init(date: Date, compositeScore: Double, spyClose: Double) {
        self.date = date
        self.compositeScore = compositeScore
        self.spyClose = spyClose
    }
}

// MARK: - Indicator Historical Data
public struct IndicatorHistoricalDataItem: Codable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let value: Double
    public let percentileRank: Double?

    public init(date: Date, value: Double, percentileRank: Double?) {
        self.date = date
        self.value = value
        self.percentileRank = percentileRank
    }
}