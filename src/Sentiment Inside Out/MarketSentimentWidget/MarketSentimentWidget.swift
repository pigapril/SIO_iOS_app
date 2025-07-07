import WidgetKit
import SwiftUI
import iOSAppSource

// MARK: - 1. Widget 的主要進入點
struct MarketSentimentWidget: Widget {
    let kind: String = "MarketSentimentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentimentProvider()) { entry in
            MarketSentimentWidgetEntryView(entry: entry)
                .widgetBackground()
                .widgetURL(URL(string: "sioapp://market-sentiment"))
        }
        .configurationDisplayName("市場情緒儀表板")
        .description("快速查看最新的 SIO 恐懼貪婪指數。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 2. Widget 內容視圖
struct MarketSentimentWidgetEntryView : View {
    var entry: SentimentProvider.SimpleEntry
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - 3. 處理背景的 View Extension
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) {
                widgetGradientBackground()
            }
        } else {
            background(widgetGradientBackground())
        }
    }
}

// MARK: - 4. 可重用的漸層背景
@ViewBuilder
func widgetGradientBackground() -> some View {
    LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 5. 各尺寸 Widget 的具體視圖
struct SmallWidgetView: View {
    var data: SentimentWidgetData
    var body: some View {
        VStack {
            Text("分數")
            Text(String(format: "%.0f", data.score))
                .font(.largeTitle)
                .bold()
            Text(data.sentimentKey) // 假設您有本地化設定
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    var data: SentimentWidgetData
    var body: some View {
        HStack {
            SmallWidgetView(data: data)
            VStack(alignment: .leading) {
                ForEach(data.indicators) { indicator in
                    Text(indicator.name)
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    var data: SentimentWidgetData
    var body: some View {
        VStack {
            MediumWidgetView(data: data)
            // 可加入更多資訊
        }
        .padding()
    }
}

// MARK: - 6. Widget 的資料提供者
struct SentimentProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let data = await WidgetDataProvider.fetchSentimentData()
            let entry = SimpleEntry(date: .now, data: data)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    struct SimpleEntry: TimelineEntry {
        let date: Date
        let data: SentimentWidgetData
    }
}

// MARK: - 7. 預覽用的 Placeholder 資料
extension SentimentWidgetData {
    static var placeholder: SentimentWidgetData {
        .init(score: 50, sentimentKey: "中性", lastUpdated: Date(), indicators: [
            // 現在可以順利地呼叫 public init
            .init(name: "VIX 恐慌指數", value: 15, percentile: 50),
            .init(name: "AAII 散戶情緒", value: 0.1, percentile: 55),
            .init(name: "CBOE 買/賣權比例", value: 0.8, percentile: 60)
        ])
    }
}