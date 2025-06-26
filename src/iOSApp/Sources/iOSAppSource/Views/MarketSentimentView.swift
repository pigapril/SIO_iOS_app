// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Views/MarketSentimentView.swift

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
        
        var localized: LocalizedStringKey {
            return LocalizedStringKey(self.rawValue)
        }
    }
    
    @State private var selectedView: SentimentViewType = .overview

    public init() {}

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
        .navigationTitle(Text("nav.marketSentiment", bundle: .module))
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

                SemiCircleGaugeView(value: score, showLabels: true)
                    .frame(height: 250)
                    .offset(y: -60)

                HStack {
                    Text("marketSentiment.lastUpdateLabel", bundle: .module)
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
                    Text("marketSentiment.viewMode.timeline", bundle: .module)
                        .font(.title2.bold())
                    Spacer()
                    Menu {
                        ForEach(TimeRangeOption.allCases) { range in
                            Button(action: { viewModel.setDateRange(for: range) }) {
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

                if let range = viewModel.dateRange, let fullBounds = viewModel.fullDateRange {
                    RangeSliderView(
                        value: Binding(
                            get: { viewModel.dateRange ?? fullBounds },
                            set: { viewModel.dateRange = $0 }
                        ),
                        bounds: fullBounds
                    ) { isEditing in
                        if !isEditing {
                            viewModel.updateChartData()
                        }
                    }
                    // --- MODIFICATION: Increased frame height for more vertical space ---
                    .frame(height: 60)
                    .padding(.horizontal)
                }
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
                            indicatorName: NSLocalizedString("indicators.\(detailKey)", bundle: .module, comment: ""),
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
            Text("common.error", bundle: .module).font(.headline)
            Text(message).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding().frame(minHeight: 300)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short; return formatter
    }()
    
    private func getCompositeSections() -> [DescriptionSection] {
        let jsonKey = "marketSentiment.descriptions.composite.sections"
        let jsonString = NSLocalizedString(jsonKey, bundle: .module, comment: "JSON array of composite description sections")

        if jsonString == jsonKey {
            return []
        }
        
        guard let data = jsonString.data(using: .utf8),
              let sections = try? JSONDecoder().decode([DescriptionSection].self, from: data) else {
            return []
        }
        
        return sections
    }
}

// MARK: - Custom Range Slider Component
private struct RangeSliderView: View {
    @Binding var value: ClosedRange<Date>
    let bounds: ClosedRange<Date>
    let onEditingChanged: (Bool) -> Void

    @State private var dragOffset: CGFloat? = nil
    
    private let thumbRadius: CGFloat = 12

    private func dateToRatio(_ date: Date, in geometry: GeometryProxy) -> CGFloat {
        let totalInterval = bounds.upperBound.timeIntervalSinceReferenceDate - bounds.lowerBound.timeIntervalSinceReferenceDate
        guard totalInterval > 0 else { return 0 }
        let valueInterval = date.timeIntervalSinceReferenceDate - bounds.lowerBound.timeIntervalSinceReferenceDate
        return CGFloat(valueInterval / totalInterval) * geometry.size.width
    }

    private func ratioToDate(_ ratio: CGFloat, in geometry: GeometryProxy) -> Date {
        let totalInterval = bounds.upperBound.timeIntervalSinceReferenceDate - bounds.lowerBound.timeIntervalSinceReferenceDate
        let interval = Double(ratio / geometry.size.width) * totalInterval
        return Date(timeIntervalSinceReferenceDate: bounds.lowerBound.timeIntervalSinceReferenceDate + interval)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 6)
                
                // Selected Range Track
                let lowerPosition = dateToRatio(value.lowerBound, in: geometry)
                let upperPosition = dateToRatio(value.upperBound, in: geometry)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 6)
                    .offset(x: lowerPosition)
                    .frame(width: upperPosition - lowerPosition)

                // Lower Thumb
                thumbView
                    .position(x: lowerPosition, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { gestureValue in
                                onEditingChanged(true)
                                let newLowerDate = ratioToDate(gestureValue.location.x, in: geometry)
                                if newLowerDate < value.upperBound {
                                    self.value = newLowerDate...self.value.upperBound
                                }
                            }
                            .onEnded { _ in onEditingChanged(false) }
                    )
                
                // Upper Thumb
                thumbView
                    .position(x: upperPosition, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { gestureValue in
                                onEditingChanged(true)
                                let newUpperDate = ratioToDate(gestureValue.location.x, in: geometry)
                                if newUpperDate > value.lowerBound {
                                    self.value = self.value.lowerBound...newUpperDate
                                }
                            }
                            .onEnded { _ in onEditingChanged(false) }
                    )
            }
            .overlay(
                HStack {
                    Text(value.lowerBound, style: .date)
                    Spacer()
                    Text(value.upperBound, style: .date)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                // --- MODIFICATION: Increased padding to push dates further down ---
                .padding(.top, 55)
            )
        }
    }
    
    private var thumbView: some View {
        Circle()
            .fill(Color.white)
            .frame(width: thumbRadius * 2, height: thumbRadius * 2)
            .shadow(radius: 2)
            .overlay(Circle().stroke(Color(.systemGray3), lineWidth: 1))
    }
}


// MARK: - Other Helper Views (Unchanged)
// (ExpandableDescriptionView, IndicatorRowView, HistoricalSentimentChart)

private struct ExpandableDescriptionView: View {
    let mainTitleKey: LocalizedStringKey
    let shortDescriptionKey: LocalizedStringKey
    let sections: [DescriptionSection]
    
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(mainTitleKey, bundle: .module)
                .font(.title2.bold())
            
            Text(shortDescriptionKey, bundle: .module)
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
                    Text(isExpanded ? "common.collapse" : "common.learnMore", bundle: .module)
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
        .frame(height: 250)
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