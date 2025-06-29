import SwiftUI

/// 一個可重用的視圖，根據 stock.logo 的內容來顯示國旗、網路圖片或預設文字。
/// 這個視圖的邏輯是參照 Web 版本的 StockHeader.js 實作。
public struct StockLogoView: View {
    let stock: Stock
    let size: CGFloat

    public init(stock: Stock, size: CGFloat) {
        self.stock = stock
        self.size = size
    }

    public var body: some View {
        // 使用 ZStack 將內容疊加在預設的灰色圓圈背景上
        ZStack {
            Circle()
                .fill(Color(.systemGray6))

            logoContent
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var logoContent: some View {
        switch stock.logo {
        // 情況 1: 根據特殊字串顯示對應的國旗
        case "TW":
            // 假設 "tw-flag" 已被加到 Assets.xcassets
            Image("tw-flag", bundle: .module)
                .resizable()
                .scaledToFill()
        case "HK":
            // 假設 "hk-flag" 已被加到 Assets.xcassets
            Image("hk-flag", bundle: .module)
                .resizable()
                .scaledToFill()
        case "US_ETF":
            // 假設 "us-flag" 已被加到 Assets.xcassets
            Image("us-flag", bundle: .module)
                .resizable()
                .scaledToFill()
        
        // 情況 2: 如果是有效的 URL 字串，則使用 AsyncImage 載入
        case .some(let urlString) where URL(string: urlString) != nil:
            AsyncImage(url: URL(string: urlString)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                // 如果 URL 圖片載入失敗，顯示預設的文字圖示
                defaultSymbolView
            }
        
        // 情況 3: 如果 stock.logo 是 nil、無效的 URL 或未知的代碼
        default:
            defaultSymbolView
        }
    }

    // 預設的文字圖示 (股票代碼的第一個字母)
    private var defaultSymbolView: some View {
        Text(String(stock.symbol.prefix(1)))
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(.secondary)
    }
}