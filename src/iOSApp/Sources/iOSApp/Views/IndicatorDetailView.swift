import SwiftUI
import Charts

struct IndicatorDetail: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let content: String
}

struct IndicatorDetailView: View {
    @StateObject private var viewModel: IndicatorDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // **主要修改點**: 屬性名稱變更，使其更清晰
    private let apiIndicatorKey: String
    private let translationIndicatorKey: String

    // **主要修改點**: init 方法現在接收原始的 indicatorName
    init(indicatorName: String) {
        self.apiIndicatorKey = indicatorName
        // 內部轉換，找到用於翻譯的 key
        self.translationIndicatorKey = Self.getTranslationKey(for: indicatorName)
        _viewModel = StateObject(wrappedValue: IndicatorDetailViewModel(indicatorKey: indicatorName))
    }

    // **主要修改點**: 新增一個靜態方法，用於從 API 的 key 找到翻譯用的 key
    private static func getTranslationKey(for name: String) -> String {
        let map: [String: String] = [
            "AAII Bull-Bear Spread": "aaiiSpread",
            "CBOE Put/Call Ratio 5-Day Avg": "cboeRatio",
            "Market Momentum": "marketMomentum",
            "VIX MA50": "vixMA50",
            "Safe Haven Demand": "safeHaven",
            "Junk Bond Spread": "junkBond",
            "S&P 500 COT Index": "cotIndex",
            "NAAIM Exposure Index": "naaimIndex"
        ]
        return map[name] ?? "unknown"
    }

    private var shortDescription: String {
        NSLocalizedString("marketSentiment.descriptions.\(translationIndicatorKey).shortDescription", comment: "")
    }

    private var sections: [IndicatorDetail] {
        let jsonString = NSLocalizedString("marketSentiment.descriptions.\(translationIndicatorKey).sections", comment: "")
        guard let data = jsonString.data(using: .utf8),
              let decodedSections = try? JSONDecoder().decode([IndicatorDetail].self, from: data) else {
            return []
        }
        return decodedSections
    }
    
    private var indicatorTitle: String {
         NSLocalizedString("indicators.\(translationIndicatorKey)", comment: "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if viewModel.isLoading {
                        ProgressView().frame(height: 200)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("圖表載入失敗: \(errorMessage)").foregroundColor(.red).frame(height: 200)
                    } else if !viewModel.historicalData.isEmpty {
                        VStack(alignment: .leading) {
                            Text("歷史圖表").font(.title2.bold())
                            IndicatorHistoricalChart(data: viewModel.historicalData)
                                .frame(height: 250)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    Text(shortDescription).font(.body)

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title).font(.title2).fontWeight(.bold)
                            Text(section.content).font(.body)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(indicatorTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                if viewModel.historicalData.isEmpty {
                    viewModel.fetchData()
                }
            }
        }
    }
}

// IndicatorHistoricalChart 和 NumberFormatter extension 保持不變
struct IndicatorHistoricalChart: View {
    let data: [IndicatorHistoricalDataItem]

    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(x: .value("Date", item.date), y: .value("Value", item.value))
                    .foregroundStyle(by: .value("Series", "指標數值"))
                
                if let percentileRank = item.percentileRank {
                    LineMark(x: .value("Date", item.date), y: .value("Percentile", percentileRank))
                        .foregroundStyle(by: .value("Series", "恐懼貪婪分數 (0-100)"))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(NSNumber(value: doubleValue), formatter: NumberFormatter.currency)
                    }
                }
            }
        }
        .chartYAxisLabel("指標數值", position: .leading)
        
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")%")
            }
        }
        .chartYAxisLabel("恐懼貪婪分數", position: .trailing)
    }
}

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.minimumFractionDigits = 2; formatter.maximumFractionDigits = 2; return formatter
    }
}