// src/iOSApp/Sources/iOSAppSource/WidgetDataProvider.swift


import Foundation
import SwiftUI

// MARK: - 1. 公開給 Widget 使用的資料結構
public struct SentimentWidgetData {
    public let score: Double
    public let sentimentKey: String
    public let lastUpdated: Date
    public let indicators: [IndicatorData]
    public let errorMessage: String?

    // 巢狀結構，用於存放指標的簡化資料
    public struct IndicatorData: Identifiable {
        public var id: String { name }
        public let name: String
        public let value: Double
        public let percentile: Double

        // +++ ✨ 新增此公開的初始化方法 ✨ +++
        public init(name: String, value: Double, percentile: Double) {
            self.name = name
            self.value = value
            self.percentile = percentile
        }
    }

    // 公開的初始化方法
    public init(score: Double, sentimentKey: String, lastUpdated: Date, indicators: [IndicatorData], errorMessage: String? = nil) {
        self.score = score
        self.sentimentKey = sentimentKey
        self.lastUpdated = lastUpdated
        self.indicators = indicators
        self.errorMessage = errorMessage
    }
}

// MARK: - 2. 公開的資料提供者 (這就是我們的 "窗口")
public class WidgetDataProvider {

    public static func fetchSentimentData() async -> SentimentWidgetData {
        // ✨ Log 1: 確認 function 是否被呼叫
        print("[WidgetLog] 1. fetchSentimentData() - 開始獲取資料。")
        
        do {
            let rawData = try await APIService.shared.fetchMarketSentiment()
            
            // ✨ Log 2: 確認 API 是否成功回傳資料
            print("[WidgetLog] 2. APIService.shared.fetchMarketSentiment() - 成功。分數: \(rawData.totalScore)")
            
            guard let score = Double(rawData.totalScore) else {
                // ✨ Log 3: 記錄分數轉換失敗
                print("[WidgetLog] 3. 錯誤：分數格式不正確 - \(rawData.totalScore)")
                return self.createErrorData(message: "Invalid score format")
            }
            
            let sentimentKey = self.getSentimentKey(for: score)
            let indicatorData = rawData.indicators.compactMap { (key, indicator) -> SentimentWidgetData.IndicatorData? in
                guard let friendlyName = self.getFriendlyIndicatorName(for: key) else { return nil }
                return SentimentWidgetData.IndicatorData(name: friendlyName, value: indicator.value, percentile: indicator.percentileRank)
            }
            let sortedIndicators = indicatorData.sorted { $0.name < $1.name }

            let finalWidgetData = SentimentWidgetData(
                score: score,
                sentimentKey: sentimentKey,
                lastUpdated: rawData.compositeScoreLastUpdate,
                indicators: Array(sortedIndicators.prefix(3)),
                errorMessage: nil
            )
            
            // ✨ Log 4: 確認最終要顯示的資料
            print("[WidgetLog] 4. 成功建立 Widget 資料。指標數量: \(finalWidgetData.indicators.count)")
            return finalWidgetData

        } catch {
            // ✨ Log 5: 記錄任何從 API 來的錯誤
            print("[WidgetLog] 5. 錯誤：在 fetchSentimentData 中捕捉到錯誤 - \(error.localizedDescription)")
            ErrorHandler.handle(error: error, component: "WidgetDataProvider")
            return self.createErrorData(message: error.localizedDescription)
        }
    }
    
    // 內部輔助函式...
    private static func createErrorData(message: String) -> SentimentWidgetData {
        return SentimentWidgetData(score: 0, sentimentKey: "sentiment.notAvailable", lastUpdated: Date(), indicators: [], errorMessage: message)
    }

    private static func getSentimentKey(for score: Double?) -> String {
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
    
    private static func getFriendlyIndicatorName(for key: String) -> String? {
        switch key {
        case "VIX MA50": return "VIX 恐慌指數"
        case "AAII Bull-Bear Spread": return "AAII 散戶情緒"
        case "CBOE Put/Call Ratio 5-Day Avg": return "CBOE 買/賣權比例"
        default: return nil
        }
    }
}