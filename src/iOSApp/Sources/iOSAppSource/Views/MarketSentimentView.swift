// pigapril/sio_ios_app/SIO_iOS_app-gauge_update/src/iOSApp/Sources/iOSApp/Views/MarketSentimentView.swift

import SwiftUI
import Charts

// MARK: - Identifiable Wrapper for Sheet
// 1. NEW: Create a simple wrapper struct for the sheet item.
struct IndicatorKey: Identifiable {
    let id: String
}

// MARK: - 主視圖
public struct MarketSentimentView: View {
    @StateObject private var viewModel = MarketSentimentViewModel()
    // 2. MODIFIED: Change the state variable to use the new Identifiable struct.
    @State private var selectedIndicatorKey: IndicatorKey?
    
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
            VStack(spacing: 0) {
                Picker("View Mode", selection: $selectedView) {
                    ForEach(SentimentViewType.allCases) { viewType in
                        Text(viewType.localized, bundle: .module).tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                switch selectedView {
                case .overview:
                    gaugeView.cardStyle() 
                case .timeline:
                    historicalChartView
                        .frame(minHeight: 400)
                        .cardStyle()                
                case .composition:
                    compositionListView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(Text("nav.marketSentiment", bundle: .module))
        .background(Color(.systemGroupedBackground))
        // 3. MODIFIED: The 'item' parameter in the sheet closure is now an IndicatorKey object.
        .sheet(item: $selectedIndicatorKey) { key in
            IndicatorDetailView(indicatorName: key.id)
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
            VStack(spacing: 15) {
                let score = Double(sentimentData.totalScore) ?? 0.0
                let sentimentKey = viewModel.sentimentKey(for: score)

                // 1. 儀表盤上方的結果標籤
                HStack(alignment: .center, spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f", score))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("marketSentiment.composite.scoreLabel", bundle: .module)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 35)

                    VStack {
                        Text(LocalizedStringKey(sentimentKey), bundle: .module)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(viewModel.sentimentColor(for: sentimentKey))
                        Text("marketSentiment.composite.sentimentLabel", bundle: .module)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.top, 5)

                // 2. 儀表盤視圖
                SemiCircleGaugeView(value: score, viewModel: viewModel)
                    .frame(height: 250)
                    .offset(y: -60)

                // 3. 最後更新時間
                HStack {
                    Text("marketSentiment.lastUpdateLabel", bundle: .module)
                    Text(": \(sentimentData.compositeScoreLastUpdate, formatter: Self.dateFormatter)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: 5) // 向下移動
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
            VStack {
                List {
                    ForEach(displayableIndicatorKeys, id: \.self) { key in
                        if let indicator = indicators[key], let detailKey = viewModel.indicatorKey(forName: key) {
                            IndicatorRowView(
                                indicatorName: NSLocalizedString("indicators.\(detailKey)", bundle: .module, comment: ""),
                                percentileRank: indicator.percentileRank,
                                viewModel: viewModel
                            )
                            .onTapGesture { self.selectedIndicatorKey = IndicatorKey(id: key) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                // Adjust frame height based on content
                .frame(height: CGFloat(displayableIndicatorKeys.count) * 55 + 40) 
            }
            .cardStyle() // Apply card style to the list container
            
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


// MARK: - 優化後的儀表盤 (GaugeView)
struct SemiCircleGaugeView: View {
    let value: Double
    @ObservedObject var viewModel: MarketSentimentViewModel

    private var sentimentGradient: AngularGradient {
        let colors = [
            AppColors.minus2SD,        // Extreme Fear
            AppColors.minus1SD,        // Fear
            AppColors.trend,           // Neutral
            AppColors.plus1SD,         // Greed
            AppColors.plus2SD          // Extreme Greed
        ]
        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
            let radius = min(geometry.size.width / 2, geometry.size.height) * 0.9
            let lineWidth = radius * 0.25
            let needleRotation = Angle.degrees((value / 100.0) * 180.0 - 90.0)
            
            ZStack {
                // 1. 灰色背景弧形
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                    
                // 2. 漸層情緒色環
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(sentimentGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 5)

                // 3. 精緻化的指針
                NeedleShape()
                    .fill(Color(.secondaryLabel))
                    .frame(width: radius * 0.05, height: radius * 0.7) // 微調
                    .offset(y: -radius * 0.35) // 微調
                    .rotationEffect(needleRotation)
                    .position(center)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: value)
                
                // 4.  【核心修改】將數值與樞軸點結合
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                    
                    Text(String(format: "%.0f", value))
                        .font(.system(size: radius * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.label))
                }
                .frame(width: lineWidth * 1.2, height: lineWidth * 1.2)
                .position(center)
                    
                // 5. 底部標籤
                HStack {
                    Text("sentiment.extremeFear", bundle: .module)
                    Spacer()
                    Text("sentiment.extremeGreed", bundle: .module)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: radius * 2.1)
                .position(x: center.x, y: center.y + 35)
            }
        }
    }
}


// 輔助形狀：自定義指針外觀
struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.closeSubpath()
        return path
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
                    AxisGridLine().foregroundStyle(.clear)
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