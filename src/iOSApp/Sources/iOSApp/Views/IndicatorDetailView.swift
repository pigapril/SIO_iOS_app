import SwiftUI
import Charts

// MARK: - 主視圖
struct IndicatorDetailView: View {
    @StateObject private var viewModel: IndicatorDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 用於本地化的翻譯鍵
    private let indicatorTitleKey: String
    private let descriptionShortKey: String
    private let descriptionSectionsKey: String

    init(indicatorName: String) {
        let key = Self.getTranslationKey(for: indicatorName)
        self.indicatorTitleKey = "indicators.\(key)"
        self.descriptionShortKey = "marketSentiment.descriptions.\(key).shortDescription"
        self.descriptionSectionsKey = "marketSentiment.descriptions.\(key).sections"
        // 使用 StateObject 的 wrappedValue 來初始化 ViewModel
        _viewModel = StateObject(wrappedValue: IndicatorDetailViewModel(indicatorKey: indicatorName))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else {
                        summaryView
                        chartView
                        descriptionView
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text(LocalizedStringKey(indicatorTitleKey), bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() } // "Done" 應該也要本地化
                }
            }
            .onAppear(perform: viewModel.fetchData)
        }
    }

    // MARK: - 子視圖

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("indicatorItem.latestDataLabel", bundle: .module)
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                MetricView(
                    labelKey: "indicatorItem.valueLabel",
                    value: viewModel.latestIndicatorData?.value.formatted(.number.precision(.fractionLength(2))) ?? "N/A"
                )
                Divider()
                MetricView(
                    labelKey: "indicatorItem.fearGreedScoreLabel",
                    value: viewModel.latestIndicatorData?.percentileRank?.formatted(.number.precision(.fractionLength(0))) ?? "N/A"
                )
            }
        }
        .cardStyle()
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("歷史走勢", bundle: .module)
                    .font(.title3.bold())
                Spacer()
                Menu {
                    ForEach(IndicatorDetailViewModel.TimeRangeOption.allCases) { option in
                        Button(action: {
                            viewModel.filterData(for: option)
                        }) {
                            Text(LocalizedStringKey(option.localizedKey), bundle: .module)
                        }
                    }
                } label: {
                    HStack {
                        Text(LocalizedStringKey(viewModel.selectedTimeRange.localizedKey), bundle: .module)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            
            IndicatorHistoricalChart(data: viewModel.filteredHistoricalData)
                .frame(height: 250)
        }
        .cardStyle()
    }

    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(LocalizedStringKey(descriptionShortKey), bundle: .module)
                .font(.body)
                .foregroundColor(.secondary)
            
            ForEach(getSections()) { section in
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.title).font(.headline)
                    Text(section.content).font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }

    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("資料載入錯誤")
                .font(.headline)
                .padding(.top, 4)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - 輔助函式

    private func getSections() -> [IndicatorDetailSection] {
        let jsonString = NSLocalizedString(descriptionSectionsKey, bundle: .module, comment: "JSON array of sections")
        guard let data = jsonString.data(using: .utf8),
              let sections = try? JSONDecoder().decode([IndicatorDetailSection].self, from: data) else {
            return []
        }
        return sections
    }
    
    private static func getTranslationKey(for name: String) -> String {
        let map = [
            "AAII Bull-Bear Spread": "aaiiSpread", "CBOE Put/Call Ratio 5-Day Avg": "cboeRatio",
            "Market Momentum": "marketMomentum", "VIX MA50": "vixMA50",
            "Safe Haven Demand": "safeHaven", "Junk Bond Spread": "junkBond",
            "S&P 500 COT Index": "cotIndex", "NAAIM Exposure Index": "naaimIndex"
        ]
        return map[name] ?? "unknown"
    }
}

// 可重用的指標數據視圖
struct MetricView: View {
    let labelKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.title2.bold())
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 指標描述區塊的資料結構
struct IndicatorDetailSection: Codable, Identifiable {
    var id: String { title }
    let title: String
    let content: String
}

// MARK: - 圖表視圖 (已修正)
struct IndicatorHistoricalChart: View {
    let data: [IndicatorHistoricalDataItem]

    private var valueDomain: ClosedRange<Double> {
        let values = data.map(\.value)
        guard let min = values.min(), let max = values.max(), min != max else {
            return (values.first ?? 0)...((values.first ?? 0) + 1)
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // 左 Y 軸：情緒分數 (百分位數)
                Chart {
                    ForEach(data) { item in
                        if let rank = item.percentileRank {
                            LineMark(
                                x: .value("日期", item.date),
                                y: .value("情緒分數", rank)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisTick()
                        // **FIXED**: 使用空的 Text View 來隱藏 Y 軸數值
                        AxisValueLabel { Text("") }
                    }
                }

                // 右 Y 軸：指標原始數值
                Chart {
                    ForEach(data) { item in
                        AreaMark(
                            x: .value("日期", item.date),
                            y: .value("指標數值", item.value)
                        )
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0)]), startPoint: .top, endPoint: .bottom))
                        
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("指標數值", item.value)
                        )
                        .foregroundStyle(Color.orange)
                    }
                }
                .chartYScale(domain: valueDomain)
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick()
                        // **FIXED**: 使用空的 Text View 來隱藏 Y 軸數值
                        AxisValueLabel { Text("") }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartLegend(.hidden)
            
            // 自定義圖例
            HStack(spacing: 20) {
                legendItem(color: .orange, label: "指標數值")
                legendItem(color: .blue, label: "情緒分數 (0-100)")
            }
            .padding(.top, 5)
        }
    }

    private func legendItem(color: Color, label: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(color).frame(width: 15, height: 3)
            Text(label, bundle: .module).font(.caption).foregroundColor(.secondary)
        }
    }
}
