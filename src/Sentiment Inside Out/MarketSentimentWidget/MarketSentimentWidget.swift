import WidgetKit
import SwiftUI
import iOSAppSource // Widget 唯一需要 import 的就是我們的主函式庫

// MARK: - 1. Timeline Provider
struct SentimentProvider: TimelineProvider {
    // Entry 現在只包含我們乾淨的 WidgetData
    struct SimpleEntry: TimelineEntry {
        let date: Date
        let data: SentimentWidgetData
    }

    func placeholder(in context: Context) -> SimpleEntry {
        let placeholderData = SentimentWidgetData(score: 50, sentimentKey: "sentiment.neutral", lastUpdated: Date(), indicators: [], errorMessage: "載入中...")
        return SimpleEntry(date: Date(), data: placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            // 直接呼叫我們公開的 "窗口"
            let data = await WidgetDataProvider.fetchSentimentData()
            let entry = SimpleEntry(date: Date(), data: data)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            // 直接呼叫我們公開的 "窗口"
            let data = await WidgetDataProvider.fetchSentimentData()
            let entry = SimpleEntry(date: Date(), data: data)
            
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

// MARK: - 2. Widget View
struct MarketSentimentWidgetEntryView : View {
    var entry: SentimentProvider.SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        @unknown default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - 3. Widget Configuration
struct MarketSentimentWidget: Widget {
    let kind: String = "MarketSentimentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentimentProvider()) { entry in
            MarketSentimentWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "sioapp://market-sentiment"))
        }
        .configurationDisplayName("市場情緒儀表板")
        .description("快速查看最新的 SIO 恐懼貪婪指數。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Helper Functions & Views
private func sentimentColor(for sentimentKey: String) -> Color {
    // 這些輔助函式現在可以直接使用 iOSAppSource 中的公開類型
    switch sentimentKey {
    case "sentiment.extremeFear": return AppColors.minus2SD
    case "sentiment.fear": return AppColors.minus1SD
    case "sentiment.neutral": return AppColors.trend
    case "sentiment.greed": return AppColors.plus1SD
    case "sentiment.extremeGreed": return AppColors.plus2SD
    default: return Color.gray
    }
}

// MARK: - Widget Views for Different Sizes
struct SmallWidgetView: View {
    let data: SentimentWidgetData

    var body: some View {
        VStack(spacing: 8) {
            if let errorMessage = data.errorMessage {
                 Text("資料錯誤").font(.caption).foregroundColor(.red)
                 Text(errorMessage).font(.caption2).multilineTextAlignment(.center).padding(.horizontal, 4)
            } else {
                Text(data.sentimentKey.localized())
                    .font(.title3).bold()
                    .foregroundColor(sentimentColor(for: data.sentimentKey))
                Text(String(format: "%.0f", data.score))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("SIO 恐懼貪婪指數")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }.padding()
    }
}

struct MediumWidgetView: View {
    let data: SentimentWidgetData

    var body: some View {
        HStack {
            if let errorMessage = data.errorMessage {
                VStack {
                    Text("無法載入資料").font(.headline)
                    Text(errorMessage).font(.caption).foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SIO 恐懼貪婪指數").font(.headline)
                    Text(data.sentimentKey.localized()).font(.title2).bold().foregroundColor(sentimentColor(for: data.sentimentKey))
                    Text(String(format: "%.0f", data.score)).font(.system(size: 44, weight: .bold, design: .rounded))
                    Spacer()
                    Text("最後更新: \(data.lastUpdated, formatter: itemFormatter)").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                SemiCircleGaugeView(value: data.score, showLabels: false).frame(width: 120, height: 80)
            }
        }.padding()
    }
}

struct LargeWidgetView: View {
    let data: SentimentWidgetData

    var body: some View {
        VStack(alignment: .leading) {
            if let errorMessage = data.errorMessage {
                 Text(errorMessage)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("市場情緒").font(.headline)
                        Text(data.sentimentKey.localized()).font(.largeTitle).bold().foregroundColor(sentimentColor(for: data.sentimentKey))
                    }
                    Spacer()
                    Text(String(format: "%.0f", data.score)).font(.system(size: 60, weight: .bold, design: .rounded))
                }
                Divider().padding(.vertical, 8)
                Text("主要成分指標").font(.subheadline).bold()
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(data.indicators) { indicator in
                        IndicatorRow(name: indicator.name, value: indicator.value, percentile: indicator.percentile)
                    }
                }
            }
            Spacer()
        }.padding()
    }
}

struct IndicatorRow: View {
    let name: String
    let value: Double
    let percentile: Double

    var body: some View {
        HStack {
            Text(name).font(.callout)
            Spacer()
            Text(String(format: "%.2f", value)).font(.callout.monospacedDigit())
            let key = sentimentKey(for: percentile) // 使用本地的輔助函式
            Text(key.localized()).font(.caption).padding(.horizontal, 6).padding(.vertical, 2).background(sentimentColor(for: key).opacity(0.2)).foregroundColor(sentimentColor(for: key)).cornerRadius(4)
        }
    }
}

// 本地輔助函式
private func sentimentKey(for score: Double?) -> String {
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
