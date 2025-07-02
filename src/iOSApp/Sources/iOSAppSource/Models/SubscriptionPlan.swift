import Foundation

/// 定義 App 內訂閱方案的資料結構。
/// 這是一個可供全局使用的唯一數據模型。
public struct SubscriptionPlan: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let price: String
    public let period: String
    public let description: String
    public let badge: String? // 用於顯示 "贈送2個月" 等優惠標籤

    // 提供一個公開的初始化方法，以便從其他模組訪問
    public init(id: String, title: String, price: String, period: String, description: String, badge: String? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.period = period
        self.description = description
        self.badge = badge
    }
}