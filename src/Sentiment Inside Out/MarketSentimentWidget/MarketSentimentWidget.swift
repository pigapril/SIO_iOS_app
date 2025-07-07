// MARK: - 3. Widget Configuration (修正版)
struct MarketSentimentWidget: Widget {
    let kind: String = "MarketSentimentWidget"

    var body: some WidgetConfiguration {
        let configuration = StaticConfiguration(kind: kind, provider: SentimentProvider()) { entry in
            MarketSentimentWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "sioapp://market-sentiment"))
        }
        .configurationDisplayName("市場情緒儀表板")
        .description("快速查看最新的 SIO 恐懼貪婪指數。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        
        // 正確的 iOS 17 相容性處理
        if #available(iOS 17.0, *) {
            return configuration
                .containerBackground(for: .widget) {
                    widgetGradientBackground()
                }
        } else {
            return configuration
        }
    }
}

// MARK: - 修正後的 Widget Entry View
struct MarketSentimentWidgetEntryView : View {
    var entry: SentimentProvider.SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        // 根據 family 決定要顯示的內容
        let contentView = Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(data: entry.data)
            case .systemMedium:
                MediumWidgetView(data: entry.data)
            case .systemLarge:
                LargeWidgetView(data: entry.data)
            case .systemExtraLarge:
                LargeWidgetView(data: entry.data)
            case .accessoryCircular:
                SmallWidgetView(data: entry.data)
            case .accessoryRectangular:
                MediumWidgetView(data: entry.data)
            case .accessoryInline:
                SmallWidgetView(data: entry.data)
            @unknown default:
                SmallWidgetView(data: entry.data)
            }
        }
        
        // 根據 iOS 版本應用背景 - 修正版
        if #available(iOS 17.0, *) {
            // iOS 17+ 使用 containerBackground API (在 Widget Configuration 中處理)
            contentView
        } else {
            // iOS 16 及以下使用傳統背景
            contentView
                .background(widgetGradientBackground())
        }
    }
}

// MARK: - 更好的解決方案：使用 View Extension
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self
                .containerBackground(for: .widget) {
                    widgetGradientBackground()
                }
        } else {
            self
                .background(widgetGradientBackground())
        }
    }
}

// MARK: - 使用 Extension 的簡潔版本
struct MarketSentimentWidgetSimple: Widget {
    let kind: String = "MarketSentimentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentimentProvider()) { entry in
            MarketSentimentWidgetEntryView(entry: entry)
                .widgetBackground() // 使用我們的 extension
                .widgetURL(URL(string: "sioapp://market-sentiment"))
        }
        .configurationDisplayName("市場情緒儀表板")
        .description("快速查看最新的 SIO 恐懼貪婪指數。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}