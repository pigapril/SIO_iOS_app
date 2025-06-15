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
                    Button("完成") { dismiss() }
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


// MARK: - 圖表視圖 (已修正對齊與編譯問題)
struct IndicatorHistoricalChart: View {
    let data: [IndicatorHistoricalDataItem]
    @State private var selectedDate: Date?
    @State private var selectedValues: [String: Double]?

    // 1. 定義主軸 (情緒分數) 的數據域
    private let primaryDomain: ClosedRange<Double> = 0...100
    
    // 2. 計算副軸 (指標數值) 的數據域
    private var secondaryDomain: ClosedRange<Double> {
        let values = data.map(\.value)
        guard let min = values.min(), let max = values.max(), min != max else {
            // 處理數據為空或數值全部相同的邊界情況
            let val = values.first ?? 0
            return (val - 1)...(val + 1)
        }
        let padding = (max - min) * 0.1 // 增加一點邊界，避免圖形貼邊
        return (min - padding)...(max + padding)
    }
    
    // 3. 手動計算刻度值
    private var axisValues: (primary: [Double], secondary: [Double]) {
        let desiredTickCount = 5 // 定義你想要的網格線/刻度數量
        
        // 主軸的刻度 (例如：0, 25, 50, 75, 100)
        let primaryTicks = stride(from: primaryDomain.lowerBound, through: primaryDomain.upperBound, by: primaryDomain.upperBound / Double(desiredTickCount - 1)).map { $0 }
        
        // 副軸的刻度
        let secondaryTicks = primaryTicks.map { primaryValue -> Double in
            // 將主軸刻度值從 [0, 100] 的範圍正規化到 [0, 1]
            let normalizedValue = (primaryValue - primaryDomain.lowerBound) / (primaryDomain.upperBound - primaryDomain.lowerBound)
            
            // 將正規化後的值映射到副軸的數據範圍
            let secondaryRange = secondaryDomain.upperBound - secondaryDomain.lowerBound
            return secondaryDomain.lowerBound + (normalizedValue * secondaryRange)
        }
        
        return (primaryTicks, secondaryTicks)
    }
    
    // Tooltip Helper
    struct TidyChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let series: String
    }
    
    private let seriesKeyMap: [String: Color] = [
        "指標數值": .orange,
        "情緒分數": .blue
    ]

    private var dataWithRank: [IndicatorHistoricalDataItem] {
        data.filter { $0.percentileRank != nil }
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Y 軸 1：情緒分數 (百分位數) - 負責畫網格線
                if !dataWithRank.isEmpty {
                    Chart {
                        ForEach(dataWithRank) { item in
                            LineMark(
                                x: .value("日期", item.date),
                                y: .value("情緒分數", item.percentileRank!)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .chartYScale(domain: primaryDomain)
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: axisValues.primary) { _ in
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                }

                // Y 軸 2：指標原始數值
                if !data.isEmpty {
                    Chart {
                        ForEach(data) { item in
                            // ✅ *** 修正點：移除 AreaMark ***
                            // AreaMark(x: .value("日期", item.date), y: .value("指標數值", item.value))
                            //     .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0)]), startPoint: .top, endPoint: .bottom))
                            
                            LineMark(x: .value("日期", item.date), y: .value("指標數值", item.value))
                                .foregroundStyle(Color.orange)
                        }
                        
                        // RuleMark 必須被放置在 Chart 的內容中
                        if let selectedDate {
                            RuleMark(x: .value("Date", selectedDate))
                                .foregroundStyle(Color.gray.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                        }
                    }
                    .chartYScale(domain: secondaryDomain)
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: axisValues.secondary) { _ in
                            AxisGridLine().foregroundStyle(.clear)
                            AxisTick()
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSelection(at: value.location, proxy: proxy, geometry: geometry.size)
                                }
                                .onEnded { _ in
                                    selectedDate = nil
                                    selectedValues = nil
                                }
                        )
                }
            }
            .chartOverlay { proxy in
                // Tooltip 視圖
                if let selectedDate, let selectedValues {
                    chartTooltip(selectedDate: selectedDate, selectedValues: selectedValues, proxy: proxy)
                } else {
                    EmptyView()
                }
            }
            
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
    
    @ViewBuilder
    private func chartTooltip(selectedDate: Date, selectedValues: [String: Double], proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            let sortedItems = selectedValues.sorted { $0.value > $1.value }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                
                ForEach(sortedItems, id: \.key) { seriesKey, value in
                    HStack {
                        Circle()
                            .fill(seriesKeyMap[seriesKey] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(LocalizedStringKey(seriesKey), bundle: .module)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.2f", value))
                            .font(.caption.bold())
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor.systemBackground).opacity(0.85).cornerRadius(8))
            .shadow(radius: 4)
            .frame(width: 150)
            .position(
                x: {
                    let datePosition = proxy.position(forX: selectedDate) ?? 0
                    if datePosition < geometry.size.width / 2 {
                        return datePosition + 80
                    } else {
                        return datePosition - 80
                    }
                }(),
                y: geometry.size.height / 2 - 50
            )
        }
    }

    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: CGSize) {
        guard location.x >= 0, location.x <= geometry.width else {
            self.selectedDate = nil
            self.selectedValues = nil
            return
        }
        guard let date: Date = proxy.value(atX: location.x) else { return }
        
        self.selectedDate = date
        
        let allPoints = transformData()
        let closestPoints = Dictionary(grouping: allPoints, by: { $0.series })
            .mapValues { seriesPoints -> TidyChartDataPoint? in
                seriesPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
            }

        var newValues: [String: Double] = [:]
        for (series, point) in closestPoints {
            if let point {
                newValues[series] = point.value
            }
        }
        
        self.selectedValues = newValues
    }
    
    private func transformData() -> [TidyChartDataPoint] {
        var tidyData: [TidyChartDataPoint] = []
        for item in data {
            tidyData.append(TidyChartDataPoint(date: item.date, value: item.value, series: "指標數值"))
            if let rank = item.percentileRank {
                tidyData.append(TidyChartDataPoint(date: item.date, value: rank, series: "情緒分數"))
            }
        }
        return tidyData
    }
}
