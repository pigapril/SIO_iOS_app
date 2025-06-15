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
                    Group { historicalChartView }.cardStyle()
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
                        ForEach(["1M", "3M", "6M", "1Y", "3Y", "5Y", "All"], id: \.self) { range in
                            Button(range.displayString) { viewModel.filterData(for: range) }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedTimeRange.displayString)
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding([.horizontal, .top])

                HistoricalSentimentChart(data: viewModel.filteredHistoricalData)
                    .frame(height: 300)
                
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
            .frame(minHeight: CGFloat(displayableIndicatorKeys.count) * 55) // 動態最小高度
            .overlay {
                if displayableIndicatorKeys.isEmpty && !viewModel.isLoading {
                    Text("No component indicators to display.").foregroundColor(.secondary)
                }
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage).padding()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
            Text("Error").font(.headline)
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
                let sentiment = viewModel.sentiment(for: percentileRank)
                Text(sentiment).font(.footnote).fontWeight(.medium).foregroundColor(viewModel.sentimentColor(for: sentiment))
                ProgressView(value: percentileRank, total: 100).progressViewStyle(LinearProgressViewStyle(tint: viewModel.sentimentColor(for: sentiment))).frame(width: 80)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }.contentShape(Rectangle())
    }
}

struct SemiCircleGaugeView: View {
    let value: Double
    @ObservedObject var viewModel: MarketSentimentViewModel
    
    private var sentiment: String { viewModel.sentiment(for: value) }
    private var color: Color { viewModel.sentimentColor(for: sentiment) }

    var body: some View {
        ZStack {
            Circle().trim(from: 0.5, to: 1.0).stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 35, lineCap: .round))
            Circle().trim(from: 0.5, to: 0.5 + (value / 100.0) / 2.0).stroke(color, style: StrokeStyle(lineWidth: 35, lineCap: .round)).animation(.easeInOut(duration: 1.0), value: value)
            VStack(spacing: 4) {
                Text(String(format: "%.0f", value)).font(.system(size: 70, weight: .bold))
                Text(sentiment).font(.title2.bold()).foregroundColor(color)
            }.offset(y: -40)
            HStack {
                Text("sentiment.extremeFear", bundle: .module).font(.callout).foregroundColor(.secondary)
                Spacer()
                Text("sentiment.extremeGreed", bundle: .module).font(.callout).foregroundColor(.secondary)
            }.offset(y: 40)
        }.padding(.horizontal, 20)
    }
}

struct HistoricalSentimentChart: View {
    let data: [HistoricalDataItem]
    
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
                    AreaMark(x: .value("Date", item.date), y: .value("Score", item.compositeScore)).foregroundStyle(.linearGradient(stops: [.init(color: Color(hex: "#D24A93").opacity(0.6), location: 0.0), .init(color: Color(hex: "#708090").opacity(0.4), location: 0.5), .init(color: .blue.opacity(0.0), location: 1.0)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", item.date), y: .value("Score", item.compositeScore)).foregroundStyle(Color(hex: "#9D00FF"))
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    // **最終修正點**
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)))
                }
            }
            
            Chart {
                ForEach(data) { item in
                    LineMark(x: .value("Date", item.date), y: .value("S&P 500", item.spyClose)).foregroundStyle(.gray.opacity(0.8))
                }
            }
            .chartYScale(domain: spyDomain)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine().foregroundStyle(.clear)
                    // **最終修正點**
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)))
                }
            }
        }
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
        
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                Rectangle().fill(Color(hex: "#9D00FF")).frame(width: 15, height: 3)
                Text("marketSentiment.chart.compositeIndexLabel", bundle: .module).font(.caption)
            }
            HStack(spacing: 5) {
                Rectangle().fill(.gray.opacity(0.8)).frame(width: 15, height: 3)
                Text("marketSentiment.chart.spyPriceLabel", bundle: .module).font(.caption)
            }
        }.padding(.top, 5)
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
            .padding([.horizontal, .bottom]) // 將 .horizontal 和 .bottom 合併
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