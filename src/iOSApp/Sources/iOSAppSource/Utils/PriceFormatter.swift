// File: src/iOSApp/Sources/iOSAppSource/Utils/PriceFormatter.swift
// Timestamp: 2025-06-26T22:40:46+08:00

import Foundation

/// 一個提供靜態方法的工具，用於格式化整個 App 中的價格顯示。
///
/// 這個工具的邏輯是為了模仿 Web 版本的 priceUtils.js，
/// 根據價格的大小來決定顯示的小數位數。
public struct PriceFormatter {

    /// 根據價格動態格式化為字串。
    /// - 規則：
    ///   - 如果價格大於或等於 10，則不顯示小數位。
    ///   - 如果價格小於 10，則顯示到小數點後兩位。
    /// - Parameter price: 需要被格式化的 `Double` 類型價格。
    /// - Returns: 格式化後的價格字串，或在價格為 nil 時返回 "-"。
    public static func format(price: Double?) -> String {
        guard let price = price else { return "-" }

        if price >= 10 {
            // 對於大於等於10的價格，不顯示小數
            return String(format: "%.0f", price)
        } else {
            // 對於小於10的價格，顯示兩位小數
            return String(format: "%.2f", price)
        }
    }

    /// 帶有貨幣符號的價格格式化方法。
    /// - Parameter price: 需要被格式化的 `Double` 類型價格。
    /// - Parameter currencySymbol: 貨幣符號，預設為 "$"。
    /// - Returns: 包含貨幣符號且格式化後的價格字串。
    public static func formatWithCurrency(price: Double?, currencySymbol: String = "$") -> String {
        let formattedPrice = format(price: price)
        if formattedPrice == "-" {
            return formattedPrice
        }
        return "\(currencySymbol)\(formattedPrice)"
    }
}