import SwiftUI
import Charts

// MARK: - 主視圖
public struct MarketSentimentView: View {
    @StateObject private var viewModel = MarketSentimentViewModel()
    @State private var selectedIndicatorKey: String?
    
    enum SentimentViewType: String, CaseIterable, Identifiable {
        case overview = "marketSentiment.viewMode.overview"
        case timeline = "marketSentiment.viewMode.timeline"
        case composition = "marketSentiment.cta.composition"

        var id: String { self.rawValue }
        
        var localized: LocalizedStringKey {
            return LocalizedStringKey(self.rawValue)
        }
    }
    
    @State private var selectedView: SentimentViewType = .overview

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("View Mode", selection: $selectedView) {
                    ForEach(SentimentViewType.allCases) { viewType in
                        Text(viewType.localized, bundle: .module).tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedView {
                case .overview:
                    Group { gaugeView }.cardStyle()
                case .timeline:
                    Group { historicalChartView.frame(minHeight: 400) }.cardStyle()
                case .composition:
                    compositionListView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(Text("nav.marketSentiment", bundle: .module))
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedIndicatorKey) { key in
            IndicatorDetailView(indicatorName: key)
        }
        .onAppear {
            if viewModel.sentimentData == nil {
                viewModel.fetchData()
            }
        }
    }
    
    // MARK: - 子視圖
    
    @ViewBuilder
    private var gaugeView: some View {
        if viewModel.isLoading {
            ProgressView().frame(minHeight: 300)
        } else if let sentimentData = viewModel.sentimentData {
            VStack {
                let score = Double(sentimentData.totalScore) ?? 0.0
                SemiCircleGaugeView(value: score, viewModel: viewModel)
                    .frame(height: 250)
                HStack {
                    Text("marketSentiment.lastUpdateLabel", bundle: .module)
                    Text(": \(sentimentData.compositeScoreLastUpdate, formatter: Self.dateFormatter)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 10)
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        }
    }
    
    @ViewBuilder
    private var historicalChartView: some View {
        if viewModel.isLoading && viewModel.historicalData.isEmpty {
            ProgressView().frame(minHeight: 400)
        } else if let errorMessage = viewModel.errorMessage, viewModel.historicalData.isEmpty {
            errorView(message: errorMessage)
        } else {
            VStack {
                HStack {
                    Text("marketSentiment.viewMode.timeline", bundle: .module)
                        .font(.title2.bold())
                    Spacer()
                    Menu {
                        ForEach(TimeRangeOption.allCases) { range in
                            Button(action: { viewModel.filterData(for: range) }) {
                                Text(range.localizedKey, bundle: .module)
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedTimeRange.localizedKey, bundle: .module)
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding([.horizontal, .top])

                HistoricalSentimentChart(data: viewModel.filteredHistoricalData)
                
                if let range = viewModel.dateRange, let selected = viewModel.selectedDate {
                    VStack {
                        Slider(
                            value: Binding(get: { selected.timeIntervalSinceReferenceDate }, set: { viewModel.selectedDate = Date(timeIntervalSinceReferenceDate: $0) }),
                            in: range.lowerBound.timeIntervalSinceReferenceDate...range.upperBound.timeIntervalSinceReferenceDate,
                            onEditingChanged: { if !$0 { viewModel.filterDataBySlider() } }
                        )
                        HStack {
                            Text(range.lowerBound, style: .date)
                            Spacer()
                            Text(range.upperBound, style: .date)
                        }
                        .font(.caption).foregroundColor(.secondary)
                    }.padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var compositionListView: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let indicators = viewModel.sentimentData?.indicators {
            let displayableIndicatorKeys = indicators.keys.sorted().filter { $0 != "Investment Grade Bond Yield" && $0 != "Junk Bond Yield" }
            List {
                ForEach(displayableIndicatorKeys, id: \.self) { key in
                    if let indicator = indicators[key], let detailKey = viewModel.indicatorKey(forName: key) {
                        IndicatorRowView(
                            indicatorName: NSLocalizedString("indicators.\(detailKey)", bundle: .module, comment: ""),
                            percentileRank: indicator.percentileRank,
                            viewModel: viewModel
                        )
                        .onTapGesture { self.selectedIndicatorKey = key }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .frame(minHeight: CGFloat(displayableIndicatorKeys.count) * 55)
            .overlay {
                if displayableIndicatorKeys.isEmpty && !viewModel.isLoading {
                    Text("marketSentiment.composition.noIndicators", bundle: .module).foregroundColor(.secondary)
                }
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage).padding()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
            Text("common.error", bundle: .module).font(.headline)
            Text(message).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding().frame(minHeight: 300)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short; return formatter
    }()
}

// MARK: - 子元件

struct IndicatorRowView: View {
    let indicatorName: String
    let percentileRank: Double
    @ObservedObject var viewModel: MarketSentimentViewModel
    
    var body: some View {
        HStack {
            Text(indicatorName).font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                let sentimentKey = viewModel.sentimentKey(for: percentileRank)
                Text(LocalizedStringKey(sentimentKey), bundle: .module)
                    .font(.footnote).fontWeight(.medium)
                    .foregroundColor(viewModel.sentimentColor(for: sentimentKey))
                ProgressView(value: percentileRank, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: viewModel.sentimentColor(for: sentimentKey)))
                    .frame(width: 80)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }.contentShape(Rectangle())
    }
}

// MARK: - 全新設計的儀表盤 (GaugeView)
struct SemiCircleGaugeView: View {
    let value: Double
    @ObservedObject var viewModel: MarketSentimentViewModel

    // 使用 AppColors 中定義的顏色以保持一致性
    private let gaugeColors = [
        AppColors.minus2SD,        // Extreme Fear
        AppColors.minus1SD,        // Fear
        AppColors.trend,           // Neutral
        AppColors.plus1SD,         // Greed
        AppColors.plus2SD          // Extreme Greed
    ]
    
    // 計算指針的旋轉角度，將 0-100 的數值映射到 -90° 至 +90°
    private var needleRotation: Angle {
        .degrees((value / 100.0) * 180.0 - 90.0)
    }

    var body: some View {
        ZStack {
            // 1. 繪製五個分段顏色的圓弧背景
            ForEach(0..<gaugeColors.count, id: \.self) { index in
                Circle()
                    .trim(from: 0.5 + (Double(index) * 0.1), to: 0.5 + (Double(index + 1) * 0.1))
                    .stroke(gaugeColors[index], style: StrokeStyle(lineWidth: 30, lineCap: .butt))
            }
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) // 增加陰影以提升立體感

            // 2. 繪製指針
            Rectangle()
                .frame(width: 3, height: 60) // 指針的形狀與大小
                .foregroundColor(Color(.label)) // 使用系統標籤顏色以確保對比度
                .offset(y: -30) // 將指針向上移動，使其底部對齊中心點
                .rotationEffect(needleRotation)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: value) // 為指針添加彈簧動畫

            // 3. 繪製指針的中心樞軸點
            Circle()
                .frame(width: 15, height: 15)
                .foregroundColor(Color(.label))
                .overlay(
                    Circle().stroke(Color(.systemBackground), lineWidth: 3)
                )

            // 4. 在儀表盤下方顯示中央的數值與文字
            VStack(spacing: 2) {
                Text(String(format: "%.0f", value))
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                
                Text(LocalizedStringKey(viewModel.sentimentKey(for: value)), bundle: .module)
                    .font(.title3.bold())
                    .foregroundColor(viewModel.sentimentColor(for: viewModel.sentimentKey(for: value)))
            }
            .offset(y: 40) // 將文字向下移動，使其位於樞軸點下方

            // 5. 在儀表盤底部兩側顯示標籤
            HStack {
                Text("sentiment.extremeFear", bundle: .module)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("sentiment.extremeGreed", bundle: .module)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 220) // 調整寬度以對齊儀表盤的兩端
            .offset(y: 100) // 將標籤向下移動到儀表盤下方

        }
        .frame(height: 250) // 為整個 ZStack 設定一個固定的框架高度
    }
}


struct HistoricalSentimentChart: View {
    let data: [HistoricalDataItem]
    
    @State private var selectedDate: Date?
    @State private var selectedValues: (score: Double, price: Double)?

    private var spyDomain: ClosedRange<Double> {
        let spyData = data.map(\.spyClose)
        guard let min = spyData.min(), let max = spyData.max(), min != max else { return (spyData.first ?? 0)...(spyData.first ?? 500) }
        let padding = (max - min) * 0.05
        return (min - padding)...(max + padding)
    }

    var body: some View {
        ZStack {
            Chart {
                ForEach(data) { item in
                    // ✅ **修正點：將顏色字串改為十六進位數字**
                    AreaMark(x: .value("Date", item.date), y: .value("Score", item.compositeScore)).foregroundStyle(.linearGradient(stops: [.init(color: Color(hex: 0xD24A93).opacity(0.6), location: 0.0), .init(color: Color(hex: 0x708090).opacity(0.4), location: 0.5), .init(color: .blue.opacity(0.0), location: 1.0)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", item.date), y: .value("Score", item.compositeScore)).foregroundStyle(Color(hex: 0x9D00FF))
                }
                
                if let selectedDate {
                    RuleMark(x: .value("Selected Date", selectedDate))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    // No AxisValueLabel to hide values
                }
            }
            
            Chart {
                ForEach(data) { item in
                    LineMark(x: .value("Date", item.date), y: .value("S&P 500", item.spyClose)).foregroundStyle(.gray.opacity(0.8))
                }
            }
            .chartYScale(domain: spyDomain)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine().foregroundStyle(.clear) // Hide secondary grid line
                    // No AxisValueLabel to hide values
                }
            }
        }
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
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
            if let selectedDate, let selectedValues {
                chartTooltip(selectedDate: selectedDate, values: selectedValues, proxy: proxy)
            }
        }
        
        // Custom Legend
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                // ✅ **修正點：將顏色字串改為十六進位數字**
                Rectangle().fill(Color(hex: 0x9D00FF)).frame(width: 15, height: 3)
                Text("marketSentiment.chart.compositeIndexLabel", bundle: .module).font(.caption)
            }
            HStack(spacing: 5) {
                Rectangle().fill(.gray.opacity(0.8)).frame(width: 15, height: 3)
                Text("marketSentiment.chart.spyPriceLabel", bundle: .module).font(.caption)
            }
        }.padding(.top, 5)
    }
    
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: CGSize) {
        guard location.x >= 0, location.x <= geometry.width,
              let date: Date = proxy.value(atX: location.x) else {
            self.selectedDate = nil
            self.selectedValues = nil
            return
        }
        
        let closestItem = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
        
        if let closestItem {
            self.selectedDate = closestItem.date
            self.selectedValues = (score: closestItem.compositeScore, price: closestItem.spyClose)
        }
    }
    
    @ViewBuilder
    private func chartTooltip(selectedDate: Date, values: (score: Double, price: Double), proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).bold().foregroundColor(.secondary)
                
                HStack {
                    // ✅ **修正點：將顏色字串改為十六進位數字**
                    Circle().fill(Color(hex: 0x9D00FF)).frame(width: 8, height: 8)
                    Text("marketSentiment.chart.tooltipScore", bundle: .module).font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", values.score)).font(.caption.bold())
                }
                
                HStack {
                    Circle().fill(.gray.opacity(0.8)).frame(width: 8, height: 8)
                    Text("marketSentiment.chart.tooltipSPY", bundle: .module).font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", values.price)).font(.caption.bold())
                }
            }
            .padding(8)
            .background(Color(UIColor.systemBackground).opacity(0.85).cornerRadius(8))
            .shadow(radius: 4)
            .frame(width: 150)
            .position(
                x: {
                    let datePosition = proxy.position(forX: selectedDate) ?? 0
                    return (datePosition < geometry.size.width / 2) ? datePosition + 80 : datePosition - 80
                }(),
                y: geometry.size.height / 2 - 50
            )
        }
    }
}


// MARK: - View Modifiers
struct CardViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding([.horizontal, .bottom])
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardViewModifier())
    }
}

extension String: Identifiable {
    public var id: String { self }
}