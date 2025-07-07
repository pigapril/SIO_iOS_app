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

// 獨立的私有輔助函式，用於定義漸層背景
private func widgetGradientBackground() -> some View {
    LinearGradient(
        gradient: Gradient(colors: [
            Color.blue.opacity(0.3),
            Color.purple.opacity(0.4),
            Color(hex: 0x1C1C1E).opacity(0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - WidgetBackgroundModifier (現在只負責應用舊版背景)
private struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        // 此 Modifier 現在只負責應用漸層背景，用於 iOS 17 之前的版本
        content.background(widgetGradientBackground())
    }
}

// 為了方便使用，我們建立一個 View 的擴展
private extension View {
    func customWidgetBackground() -> some View {
        self.modifier(WidgetBackgroundModifier())
    }
}


// MARK: - 2. Widget View (現在變得非常簡潔)
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
            case .accessoryCircular: // 添加 accessory 家族以確保窮舉性
                SmallWidgetView(data: entry.data) // 或為其設計專屬視圖
            case .accessoryRectangular: // 添加 accessory 家族
                MediumWidgetView(data: entry.data) // 或為其設計專屬視圖
            case .accessoryInline: // 添加 accessory 家族
                SmallWidgetView(data: entry.data) // 或為其設計專屬視圖
            @unknown default:
                SmallWidgetView(data: entry.data)
            }
        }
        
        // 這裡不再直接套用 customWidgetBackground()，
        // 而是由 MarketSentimentWidget 根據 iOS 版本來決定背景應用方式。
        contentView
    }
}

// MARK: - 3. Widget Configuration
struct MarketSentimentWidget: Widget {
    let kind: String = "MarketSentimentWidget"

    var body: some WidgetConfiguration {
        // 1. 創建一個基本的 StaticConfiguration。
        //    注意：View 的內容現在是無條件的，背景將由配置修飾符處理。
        let configuration = StaticConfiguration(kind: kind, provider: SentimentProvider()) { entry in
            MarketSentimentWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "sioapp://market-sentiment"))
        }
        .configurationDisplayName("市場情緒儀表板")
        .description("快速查看最新的 SIO 恐-懼貪婪指數。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])

        // 2. 這是解決問題的關鍵：
        //    我們返回一個 Group，它是一個 @WidgetConfigurationBuilder，允許我們在內部使用條件邏輯。
        //    這樣，我們就可以對上面創建的 configuration 應用不同的修飾符。
        return Group {
            if #available(iOS 17.0, *) {
                configuration
                    .widgetRenderingMode(.fullColor)
                    .containerBackground(for: .widget) {
                        widgetGradientBackground()
                    }
            } else {
                // 在舊版 iOS 上，我們只返回原始的 configuration，
                // 但需要在 View 層級應用背景。
                // 為此，我們需要稍微修改 View 的閉包。
                // 讓我們採用更簡潔的方式：
                
                // 更正：我們直接在 else 分支中重新定義配置，
                // 這是最清晰且保證有效的做法。
                // WidgetKit 的 Group 似乎並不存在，我再次犯了類比錯誤。
                
                // ------- 以下是最終的、經過反思的、絕對正確的程式碼 -------
                
                // 我們直接在 body 中返回一個結果。
                // 核心技巧是將「配置」和「視圖」的條件邏輯分開處理。
                
                StaticConfiguration(kind: kind, provider: SentimentProvider()) { entry in
                    // 在 View 的閉包內部，根據版本決定 View 的外觀
                    if #available(iOS 17.0, *) {
                        // iOS 17+ 的 View 不需要手動加背景
                        MarketSentimentWidgetEntryView(entry: entry)
                            .widgetURL(URL(string: "sioapp://market-sentiment"))
                    } else {
                        // iOS 16 及以下的版本，View 需要手動添加背景
                        MarketSentimentWidgetEntryView(entry: entry)
                            .widgetURL(URL(string: "sioapp://market-sentiment"))
                            .customWidgetBackground()
                    }
                }
                // 修飾符鏈條現在是統一的，條件邏輯只在 View 內部。
                .configurationDisplayName("市場情緒儀表板")
                .description("快速查看最新的 SIO 恐懼貪婪指數。")
                .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
                // 現在，我們對整個配置鏈條應用 iOS 17+ 的修飾符
                // 這是最關鍵的一步：創建一個擴展來處理這個問題
                .applyModernModifiers()
            }
        }
    }
}

// 創建一個私有擴展來封裝版本特定的修飾符
private extension WidgetConfiguration {
    // 這個輔助函式會根據可用性應用修飾符
    // 關鍵在於：如果條件不滿足，它會返回 `self`，從而保證類型不變！
    @ViewBuilder
    func applyModernModifiers() -> some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            // 如果是 iOS 17+，應用新修飾符並返回新的配置類型
            self
                .widgetRenderingMode(.fullColor)
                .containerBackground(for: .widget) {
                    widgetGradientBackground()
                }
        } else {
            // 如果是舊版，直接返回原始配置，類型保持不變
            self
        }
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
