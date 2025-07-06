// 檔案: MarketSentimentWidgetBundle.swift

import WidgetKit
import SwiftUI

@main
struct MarketSentimentWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 現在這個名稱和檔案1中定義的 struct 名稱完全一致了
        MarketSentimentWidget()
    }
}