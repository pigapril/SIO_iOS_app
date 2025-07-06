import Foundation
import SwiftUI // 為了 Color

// MARK: - 1. 公開給 Widget 使用的資料結構
// 這是 Widget 唯一需要認識的資料模型
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
// Widget 將會呼叫這個 class 來取得所有需要的資料
public class WidgetDataProvider {

    // 提供給 Widget 呼叫的公開靜態函式
    public static func fetchSentimentData() async -> SentimentWidgetData {
        do {
            // 在內部呼叫我們不公開的 APIService
            let rawData = try await APIService.shared.fetchMarketSentiment()
            
            // 將從 API 拿到的原始資料，轉換成 Widget 需要的乾淨、簡潔的資料
            guard let score = Double(rawData.totalScore) else {
                return self.createErrorData(message: "Invalid score format")
            }
            
            let sentimentKey = self.getSentimentKey(for: score)
            
            // 轉換指標資料
            let indicatorData = rawData.indicators.compactMap { (key, indicator) -> SentimentWidgetData.IndicatorData? in
                guard let friendlyName = self.getFriendlyIndicatorName(for: key) else { return nil }
                return SentimentWidgetData.IndicatorData(name: friendlyName, value: indicator.value, percentile: indicator.percentileRank)
            }
            
            // 排序以確保顯示順序一致
            let sortedIndicators = indicatorData.sorted { $0.name < $1.name }

            // 成功時，回傳整理好的資料
            return SentimentWidgetData(
                score: score,
                sentimentKey: sentimentKey,
                lastUpdated: rawData.compositeScoreLastUpdate,
                indicators: Array(sortedIndicators.prefix(3)), // Widget 只需顯示最重要的三個
                errorMessage: nil
            )
        } catch {
            // 任何步驟出錯，都回傳一個包含錯誤訊息的資料物件
            ErrorHandler.handle(error: error, component: "WidgetDataProvider")
            return self.createErrorData(message: error.localizedDescription)
        }
    }
    
    // 建立一個代表錯誤狀態的資料物件
    private static func createErrorData(message: String) -> SentimentWidgetData {
        return SentimentWidgetData(score: 0, sentimentKey: "sentiment.notAvailable", lastUpdated: Date(), indicators: [], errorMessage: message)
    }

    // 以下是內部輔助函式，不需要公開
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
        default: return nil // 其他不重要的指標我們就不顯示在 Widget 上
        }
    }
}
