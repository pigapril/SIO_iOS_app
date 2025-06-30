// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Views/MarketSentimentView.swift
// --- REFACTORED FOR DYNAMIC LOCALIZATION ---

import SwiftUI
import Charts

// MARK: - Identifiable Wrapper for Sheet
struct IndicatorKey: Identifiable {
    let id: String
}

// MARK: - Data Structure for Description Sections
private struct DescriptionSection: Codable, Identifiable {
    var id: String { title }
    let title: String
    let content: String
}

// MARK: - Main View
public struct MarketSentimentView: View {
    @StateObject private var viewModel = MarketSentimentViewModel()
    @State private var selectedIndicatorKey: IndicatorKey?

    enum SentimentViewType: String, CaseIterable, Identifiable {
        case overview = "marketSentiment.viewMode.overview"
        case timeline = "marketSentiment.viewMode.timeline"
        case composition = "marketSentiment.cta.composition"

        var id: String { self.rawValue }
    }
    
    @State private var selectedView: SentimentViewType = .overview

    // --- MODIFICATION START ---
    // 1. 將手勢相關的狀態變數移至 View 的頂層
    @State private var initialDateRangeForZoom: ClosedRange<Date>? = nil

    // 2. 將手勢定義為 View 的一個 computed property
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                // 在手勢開始時，記錄當前的日期範圍
                if initialDateRangeForZoom == nil {
                    initialDateRangeForZoom = viewModel.dateRange
                }
                guard let initialRange = initialDateRangeForZoom else { return }

                // 根據縮放比例計算新的時間間隔
                let originalInterval = initialRange.upperBound.timeIntervalSince(initialRange.lowerBound)
                let newInterval = originalInterval / Double(value)
                
                // 以原始範圍的中心點為基準進行縮放
                let centerPoint = initialRange.lowerBound.timeIntervalSinceReferenceDate + originalInterval / 2
                var newLowerBound = Date(timeIntervalSinceReferenceDate: centerPoint - newInterval / 2)
                var newUpperBound = Date(timeIntervalSinceReferenceDate: centerPoint + newInterval / 2)

                // 確保縮放範圍不會超過數據的總範圍
                if let fullRange = viewModel.fullDateRange {
                    newLowerBound = max(newLowerBound, fullRange.lowerBound)
                    newUpperBound = min(newUpperBound, fullRange.upperBound)
                }
                
                // 更新 ViewModel 中的日期範圍
                if newUpperBound > newLowerBound {
                    viewModel.dateRange = newLowerBound...newUpperBound
                    viewModel.updateChartData()
                }
            }
            .onEnded { _ in
                // 手勢結束時，重置初始日期範圍狀態
                initialDateRangeForZoom = nil
            }
    }
    // --- MODIFICATION END ---

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("View Mode", selection: $selectedView) {
                    ForEach(SentimentViewType.allCases) { viewType in
                        Text(viewType.rawValue.localized()).tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                switch selectedView {
                case .overview:
                    gaugeView.cardStyle()
                case .timeline:
                    historicalChartView.cardStyle()
                case .composition:
                    compositionListView.cardStyle()
                }
                
                ExpandableDescriptionView(
                    mainTitleKey: "marketSentiment.tabs.compositeIndex",
                    shortDescriptionKey: "marketSentiment.descriptions.composite.shortDescription",
                    sections: getCompositeSections()
                )
            }
            .padding(.vertical)
        }
        .navigationTitle(Text("nav.marketSentiment".localized()))
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedIndicatorKey) { key in
            IndicatorDetailView(indicatorName: key.id)
        }
        .onAppear {
            if viewModel.sentimentData == nil {
                viewModel.fetchData()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var gaugeView: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 300)
        } else if let sentimentData = viewModel.sentimentData {
            VStack(spacing: 15) {
                let score = Double(sentimentData.totalScore) ?? 0.0
                let sentimentKey = viewModel.sentimentKey(for: score)

                HStack(alignment: .center, spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f", score))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("marketSentiment.composite.scoreLabel".localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 35)

                    VStack {
                        Text(sentimentKey.localized())
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(viewModel.sentimentColor(for: sentimentKey))
                        Text("marketSentiment.composite.sentimentLabel".localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.top, 5)

                SemiCircleGaugeView(value: score, showLabels: true)
                    .frame(height: 250)
                    .offset(y: -60)

                HStack {
                    Text("marketSentiment.lastUpdateLabel".localized())
                    Text(": \(sentimentData.compositeScoreLastUpdate, formatter: Self.dateFormatter)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: 5)
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        }
    }
    
    @ViewBuilder
    private var historicalChartView: some View {
        if viewModel.isLoading && viewModel.historicalData.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
        } else if let errorMessage = viewModel.errorMessage, viewModel.historicalData.isEmpty {
            errorView(message: errorMessage)
        } else {
            VStack {
                HStack {
                    Text("marketSentiment.viewMode.timeline".localized())
                        .font(.title2.bold())
                    Spacer()
                    Menu {
                        ForEach(TimeRangeOption.allCases) { range in
                            Button(action: { viewModel.setDateRange(for: range) }) {
                                // --- 修正後: 因為 localizedKey 現在是 String，所以 .localized() 可以正常呼叫 ---
                                Text(range.localizedKey.localized())
                            }
                        }
                    } label: {
                        HStack {
                            // --- 修正後 ---
                            Text(viewModel.selectedTimeRange.localizedKey.localized())
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding([.horizontal, .top])
                HistoricalSentimentChart(data: viewModel.filteredHistoricalData)
                    .gesture(magnificationGesture)
            }
        }
    }
    
    @ViewBuilder
    private var compositionListView: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
        } else if let indicators = viewModel.sentimentData?.indicators {
            let displayableIndicatorKeys = indicators.keys.sorted().filter { $0 != "Investment Grade Bond Yield" && $0 != "Junk Bond Yield" }
            VStack {
                ForEach(displayableIndicatorKeys, id: \.self) { key in
                    if let indicator = indicators[key], let detailKey = viewModel.indicatorKey(forName: key) {
                        IndicatorRowView(
                            indicatorNameKey: "indicators.\(detailKey)",
                            percentileRank: indicator.percentileRank,
                            viewModel: viewModel
                        )
                        .padding(.horizontal)
                        .onTapGesture { self.selectedIndicatorKey = IndicatorKey(id: key) }
                        
                        if key != displayableIndicatorKeys.last {
                             Divider().padding(.leading)
                        }
                    }
                }
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage).padding()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
            Text("common.error".localized()).font(.headline)
            Text(message).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding().frame(minHeight: 300)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 將日期格式設定為 "年/月/日"
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
    
    private func getCompositeSections() -> [DescriptionSection] {
        let jsonKey = "marketSentiment.descriptions.composite.sections"
        let jsonString = jsonKey.localized()

        if jsonString == jsonKey { return [] }
        
        guard let data = jsonString.data(using: .utf8),
              let sections = try? JSONDecoder().decode([DescriptionSection].self, from: data) else {
            return []
        }
        
        return sections
    }
}

// MARK: - Helper Views
private struct ExpandableDescriptionView: View {
    let mainTitleKey: String
    let shortDescriptionKey: String
    let sections: [DescriptionSection]
    
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(mainTitleKey.localized())
                .font(.title2.bold())
            
            Text(shortDescriptionKey.localized())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 3)
            
            if isExpanded {
                Divider()
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.content)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 5)
                }
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text((isExpanded ? "common.collapse" : "common.learnMore").localized())
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.callout.weight(.semibold))
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 5)
        }
        .cardStyle()
    }
}

private struct IndicatorRowView: View {
    let indicatorNameKey: String
    let percentileRank: Double
    @ObservedObject var viewModel: MarketSentimentViewModel
    
    var body: some View {
        HStack {
            Text(indicatorNameKey.localized()).font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                let sentimentKey = viewModel.sentimentKey(for: percentileRank)
                Text(sentimentKey.localized())
                    .font(.footnote).fontWeight(.medium)
                    .foregroundColor(viewModel.sentimentColor(for: sentimentKey))
                ProgressView(value: percentileRank, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: viewModel.sentimentColor(for: sentimentKey)))
                    .frame(width: 80)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }
}

private struct HistoricalSentimentChart: View {
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
                if let selectedDate { RuleMark(x: .value("Selected Date", selectedDate)).foregroundStyle(Color.gray.opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3])) }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis { AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { _ in AxisGridLine() } }
            
            Chart {
                ForEach(data) { item in
                    LineMark(x: .value("Date", item.date), y: .value("S&P 500", item.spyClose)).foregroundStyle(.gray.opacity(0.8))
                }
            }
            .chartYScale(domain: spyDomain)
            .chartYAxis { AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { _ in AxisGridLine().foregroundStyle(.clear) } }
        }
        .frame(height: 250)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in updateSelection(at: value.location, proxy: proxy, geometry: geometry.size) }
                            .onEnded { _ in selectedDate = nil; selectedValues = nil }
                    )
            }
        }
        .chartOverlay { proxy in
            if let selectedDate, let selectedValues {
                chartTooltip(selectedDate: selectedDate, values: selectedValues, proxy: proxy)
            }
        }
        
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                Rectangle().fill(Color(hex: 0x9D00FF)).frame(width: 15, height: 3)
                Text("marketSentiment.chart.compositeIndexLabel".localized()).font(.caption)
            }
            HStack(spacing: 5) {
                Rectangle().fill(.gray.opacity(0.8)).frame(width: 15, height: 3)
                Text("marketSentiment.chart.spyPriceLabel".localized()).font(.caption)
            }
        }.padding(.top, 5)
    }
    
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: CGSize) {
        guard location.x >= 0, location.x <= geometry.width, let date: Date = proxy.value(atX: location.x) else {
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
                    Text("marketSentiment.chart.tooltipScore".localized()).font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", values.score)).font(.caption.bold())
                }
                HStack {
                    Circle().fill(.gray.opacity(0.8)).frame(width: 8, height: 8)
                    Text("marketSentiment.chart.tooltipSPY".localized()).font(.caption)
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