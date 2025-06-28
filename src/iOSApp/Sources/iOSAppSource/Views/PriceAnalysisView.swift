// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Views/PriceAnalysisView.swift

import SwiftUI
import Charts

// MARK: - Data Structures for Explanation
private struct ExplanationSectionData: Identifiable {
    let id = UUID()
    let titleKey: String
    let contentKeys: [String]
}

// MARK: - Main View
struct PriceAnalysisView: View {
    @StateObject private var viewModel: PriceAnalysisViewModel
    @State private var activeChart: ChartType = .standardDeviation
    @State private var isAdvancedQuery: Bool = false
    
    private let explanationSections: [ExplanationSectionData] = [
        .init(
            titleKey: "priceAnalysis.explanation.sd.title",
            contentKeys: [
                "priceAnalysis.explanation.sd.l1",
                "priceAnalysis.explanation.sd.l2",
                "priceAnalysis.explanation.sd.l3",
                "priceAnalysis.explanation.sd.l4"
            ]
        ),
        .init(
            titleKey: "priceAnalysis.explanation.ulBand.title",
            contentKeys: [
                "priceAnalysis.explanation.ulBand.l1",
                "priceAnalysis.explanation.ulBand.l2",
                "priceAnalysis.explanation.ulBand.l3"
            ]
        ),
        .init(
            titleKey: "priceAnalysis.explanation.combined.title",
            contentKeys: [
                "priceAnalysis.explanation.combined.l1",
                "priceAnalysis.explanation.combined.l2"
            ]
        )
    ]
    
    init(initialStockCode: String? = nil, initialYears: String? = nil) {
        _viewModel = StateObject(wrappedValue: PriceAnalysisViewModel(
            stockCode: initialStockCode ?? "SPY",
            years: initialYears ?? "3.5"
        ))
    }
    
    enum ChartType: String, CaseIterable {
        case standardDeviation = "priceAnalysis.chart.tabs.sd"
        case ulBand = "priceAnalysis.chart.tabs.ulband"
        
        // --- 修正：移除 .localized() 計算屬性 ---
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                queryCard
                chartContainer
                ExpandableExplanationView(
                    mainTitleKey: "priceAnalysis.explanation.mainTitle",
                    shortDescriptionKey: "priceAnalysis.explanation.shortDescription",
                    sections: explanationSections
                )
            }
            .padding(.vertical)
        }
        .navigationTitle(Text("priceAnalysis.pageTitle".localized()))
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if viewModel.chartData == nil {
                viewModel.fetchStockData()
            }
            viewModel.fetchHotSearches()
        }
    }
    
    // MARK: - Subviews
    
    private var queryCard: some View {
        return VStack(spacing: 15) {
            Text("priceAnalysis.form.title".localized())
                .font(.headline)
            
            HStack {
                Text("priceAnalysis.form.stockCodeLabel".localized()).frame(width: 140, alignment: .leading)
                TextField("priceAnalysis.form.stockCodePlaceholder".localized(), text: $viewModel.stockCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
            
            if !isAdvancedQuery {
                HStack {
                    Text("priceAnalysis.form.analysisPeriodLabel".localized()).frame(width: 140, alignment: .leading)
                    Picker(selection: $viewModel.analysisPeriod, label: Text("priceAnalysis.form.analysisPeriodLabel".localized())) {
                        Text("priceAnalysis.form.periodShort".localized()).tag(PriceAnalysisViewModel.AnalysisPeriod.short)
                        Text("priceAnalysis.form.periodMedium".localized()).tag(PriceAnalysisViewModel.AnalysisPeriod.medium)
                        Text("priceAnalysis.form.periodLong".localized()).tag(PriceAnalysisViewModel.AnalysisPeriod.long)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            if isAdvancedQuery {
                HStack {
                    Text("priceAnalysis.form.analysisPeriodLabel".localized()).frame(width: 140, alignment: .leading)
                    TextField("priceAnalysis.form.yearsPlaceholder".localized(), text: $viewModel.years)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                DatePicker(
                    selection: Binding(
                        get: { viewModel.backTestDate ?? Date() },
                        set: { viewModel.backTestDate = $0 }
                    ),
                    displayedComponents: .date,
                    label: { Text("priceAnalysis.form.backTestDateLabel".localized()) }
                )
            }
            
            Toggle(isOn: $isAdvancedQuery.animation()) {
                Text(isAdvancedQuery ? "priceAnalysis.form.switchToSimple".localized() : "priceAnalysis.form.switchToAdvanced".localized())
            }
            
            Button(action: {
                viewModel.fetchStockData(isManualSearch: true)
            }) {
                Text(viewModel.isLoading ? "priceAnalysis.form.buttonAnalyzing".localized() : "priceAnalysis.form.buttonStartAnalysis".localized())
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)
            
            hotSearchesSection
        }
        .cardStyle()
    }
    
    private var hotSearchesSection: some View {
        VStack {
            Text("priceAnalysis.hotSearches.title".localized())
                .font(.subheadline).bold()

            if viewModel.isLoadingHotSearches {
                ProgressView()
                    .padding(.vertical, 5)
            } else if viewModel.hotSearches.isEmpty {
                Text("priceAnalysis.hotSearches.noData".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.hotSearches) { item in
                            Button(item.keyword) {
                                viewModel.performHotSearch(item: item)
                            }
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var chartContainer: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 350)
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
            } else if let result = viewModel.analysisResult, let chartData = viewModel.chartData {
                analysisResultHeader(result: result)
                
                Picker("Chart Type", selection: $activeChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        // --- 修正：直接在 View 中使用 .rawValue 進行本地化 ---
                        Text(type.rawValue.localized()).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if activeChart == .standardDeviation {
                    PriceStandardDeviationChart(chartData: chartData)
                        .frame(height: 300)
                } else {
                    ULBandChart(chartData: chartData)
                        .frame(height: 300)
                }
                
            } else {
                Text("priceAnalysis.prompt.enterSymbol".localized())
                    .foregroundColor(.secondary)
                    .frame(height: 350)
            }
        }
        .cardStyle()
    }

    private func analysisResultHeader(result: (price: Double, sentimentKey: String)) -> some View {
        HStack{
            VStack {
                Text("priceAnalysis.result.stockCode".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.stockCode.uppercased())
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack {
                Text("priceAnalysis.result.stockPrice".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(PriceFormatter.format(price: result.price))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack {
                Text("priceAnalysis.result.marketSentiment".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(result.sentimentKey.localized())
                    .font(.headline)
                    .foregroundColor(sentimentColor(sentimentKey: result.sentimentKey))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical)
    }

    private func sentimentColor(sentimentKey: String?) -> Color {
        guard let sentimentKey = sentimentKey else { return AppColors.trend }
        switch sentimentKey {
            case "priceAnalysis.sentiment.extremeOptimism": return AppColors.plus2SD
            case "priceAnalysis.sentiment.optimism": return AppColors.plus1SD
            case "priceAnalysis.sentiment.pessimism": return AppColors.minus1SD
            case "priceAnalysis.sentiment.extremePessimism": return AppColors.minus2SD
            default: return AppColors.trend
        }
    }
}

private struct ExpandableExplanationView: View {
    let mainTitleKey: String
    let shortDescriptionKey: String
    let sections: [ExplanationSectionData]
    
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(mainTitleKey.localized())
                .font(.title2.bold())
            
            Text(shortDescriptionKey.localized())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 4)

            if isExpanded {
                Divider()
                
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.titleKey.localized())
                            .font(.headline)
                        ForEach(section.contentKeys, id: \.self) { key in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(key.localized())
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
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
                    Text(isExpanded ? "common.collapse".localized() : "common.learnMore".localized())
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


// MARK: - Sub-charts (No changes needed below this line)

private struct PriceStandardDeviationChart: View {
    let chartData: PriceAnalysisData
    @State private var selectedDate: Date?
    @State private var selectedValues: [String: Double]?

    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private func date(from string: String) -> Date {
        return isoDateFormatter.date(from: string) ?? Date()
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        let allDataPoints = chartData.prices +
                            chartData.sdAnalysis.tl_plus_2sd +
                            chartData.sdAnalysis.tl_minus_2sd
        
        guard let min = allDataPoints.compactMap({ $0 }).min(),
              let max = allDataPoints.compactMap({ $0 }).max(), min != max else {
            return (allDataPoints.first ?? 0)...(allDataPoints.first ?? 100)
        }
        
        let padding = (max - min) * 0.05
        return (min - padding)...(max + padding)
    }

    struct TidyChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let series: String
    }
    
    struct TrendDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var seriesKeyMap: [String: Color] {
        [
            "priceAnalysis.chart.label.price": AppColors.price,
            "priceAnalysis.chart.label.minus2sd": AppColors.minus2SD,
            "priceAnalysis.chart.label.minus1sd": AppColors.minus1SD,
            "priceAnalysis.chart.label.plus1sd": AppColors.plus1SD,
            "priceAnalysis.chart.label.plus2sd": AppColors.plus2SD
        ]
    }
    
    private let trendLineKey = "priceAnalysis.chart.label.trendLine"

    var body: some View {
        let (dataPoints, trendPoints) = transformData()
        let sortedSeriesKeys = seriesKeyMap.keys.sorted()
        let colorRange = sortedSeriesKeys.map { seriesKeyMap[$0]! }

        Chart {
            ForEach(dataPoints) { point in
                let lineWidth = point.series == "priceAnalysis.chart.label.price" ? 2.5 : 1.5
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .lineStyle(StrokeStyle(lineWidth: lineWidth))
            }

            ForEach(trendPoints) { point in
                let trendLineText = trendLineKey.localized()
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(trendLineText, point.value)
                )
                .foregroundStyle(AppColors.trend)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
            }
            
            if let selectedDate {
                RuleMark(x: .value("Date", selectedDate))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
            }
        }
        .chartYScale(domain: yAxisDomain)
        .chartForegroundStyleScale(domain: sortedSeriesKeys, range: colorRange)
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(preset: .automatic, values: .automatic)
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelection(at: value.location, proxy: proxy, geometry: geometry.size, data: dataPoints, trendData: trendPoints)
                            }
                            .onEnded { _ in
                                selectedDate = nil
                                selectedValues = nil
                            }
                    )
            }
        }
        .chartOverlay { proxy in
            if let selectedDate = selectedDate, let selectedValues = selectedValues {
                chartTooltip(selectedDate: selectedDate, selectedValues: selectedValues, proxy: proxy)
            }
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
                    let seriesText = seriesKey.localized()
                    HStack {
                        Circle()
                            .fill(seriesKeyMap[seriesKey] ?? AppColors.trend)
                            .frame(width: 8, height: 8)
                        Text(seriesText)
                            .font(.caption)
                        Spacer()
                        Text(PriceFormatter.format(price: value))
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

    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: CGSize, data: [TidyChartDataPoint], trendData: [TrendDataPoint]) {
        guard location.x >= 0, location.x <= geometry.width else {
            self.selectedDate = nil
            self.selectedValues = nil
            return
        }
        guard let date: Date = proxy.value(atX: location.x) else { return }
        
        self.selectedDate = date
        
        var newValues: [String: Double] = [:]
        
        let allPoints = data + trendData.map { TidyChartDataPoint(date: $0.date, value: $0.value, series: trendLineKey) }
        
        let closestPoints = Dictionary(grouping: allPoints, by: { $0.series })
            .mapValues { seriesPoints -> TidyChartDataPoint? in
                seriesPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
            }

        for (series, point) in closestPoints {
            if let point {
                newValues[series] = point.value
            }
        }
        
        self.selectedValues = newValues
    }
    
    private func transformData() -> (main: [TidyChartDataPoint], trend: [TrendDataPoint]) {
        var mainData: [TidyChartDataPoint] = []
        var trendData: [TrendDataPoint] = []
        
        let seriesKeys: [String] = [
            "priceAnalysis.chart.label.price",
            "priceAnalysis.chart.label.plus2sd",
            "priceAnalysis.chart.label.plus1sd",
            "priceAnalysis.chart.label.minus1sd",
            "priceAnalysis.chart.label.minus2sd"
        ]
        let dataArrays: [[Double]] = [
            chartData.prices,
            chartData.sdAnalysis.tl_plus_2sd,
            chartData.sdAnalysis.tl_plus_sd,
            chartData.sdAnalysis.tl_minus_sd,
            chartData.sdAnalysis.tl_minus_2sd
        ]

        guard !chartData.dates.isEmpty else { return ([], []) }

        for i in 0..<chartData.dates.count {
            let date = date(from: chartData.dates[i])
            
            if i < chartData.sdAnalysis.trendLine.count {
                trendData.append(TrendDataPoint(date: date, value: chartData.sdAnalysis.trendLine[i]))
            }
            
            for (j, seriesKey) in seriesKeys.enumerated() {
                if i < dataArrays[j].count {
                    mainData.append(TidyChartDataPoint(date: date, value: dataArrays[j][i], series: seriesKey))
                }
            }
        }
        return (mainData, trendData)
    }
}

private struct ULBandChart: View {
    let chartData: PriceAnalysisData
    @State private var selectedDate: Date?
    @State private var selectedValues: [String: Double]?
    
    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func date(from string: String) -> Date {
        return isoDateFormatter.date(from: string) ?? Date()
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        let allDataPoints = chartData.weeklyPrices + chartData.upperBand + chartData.lowerBand
        guard let min = allDataPoints.compactMap({ $0 }).min(),
              let max = allDataPoints.compactMap({ $0 }).max(), min != max else {
            return (allDataPoints.first ?? 0)...(allDataPoints.first ?? 100)
        }
        let padding = (max - min) * 0.05
        return (min - padding)...(max + padding)
    }

    struct TidyChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let series: String
    }

    private var seriesKeyMap: [String: Color] {
        [
            "ulBandChart.priceLabel": AppColors.price,
            "ulBandChart.upperBandLabel": AppColors.upperBand,
            "ulBandChart.lowerBandLabel": AppColors.lowerBand,
            "ulBandChart.ma20Label": AppColors.ma20
        ]
    }

    var body: some View {
        let dataPoints = transformToTidyData()
        let sortedSeriesKeys = seriesKeyMap.keys.sorted()
        let colorRange = sortedSeriesKeys.map { seriesKeyMap[$0]! }
        
        Chart(dataPoints) { point in
            let lineWidth = point.series == "ulBandChart.priceLabel" ? 2.5 : 1.5
            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            
            if let selectedDate {
                RuleMark(x: .value("Date", selectedDate))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
            }
        }
        .chartYScale(domain: yAxisDomain)
        .chartForegroundStyleScale(domain: sortedSeriesKeys, range: colorRange)
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(preset: .automatic, values: .automatic)
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelection(at: value.location, proxy: proxy, geometry: geometry.size, data: dataPoints)
                            }
                            .onEnded { _ in
                                selectedDate = nil
                                selectedValues = nil
                            }
                    )
            }
        }
        .chartOverlay { proxy in
            if let selectedDate = selectedDate, let selectedValues = selectedValues {
                chartTooltip(selectedDate: selectedDate, selectedValues: selectedValues, proxy: proxy)
            }
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
                    let seriesText = seriesKey.localized()
                    HStack {
                        Circle()
                            .fill(seriesKeyMap[seriesKey]!)
                            .frame(width: 8, height: 8)
                        Text(seriesText)
                            .font(.caption)
                        Spacer()
                        Text(PriceFormatter.format(price: value))
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
    
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: CGSize, data: [TidyChartDataPoint]) {
        guard location.x >= 0, location.x <= geometry.width else {
            self.selectedDate = nil
            self.selectedValues = nil
            return
        }
        guard let date: Date = proxy.value(atX: location.x) else { return }
        
        self.selectedDate = date
        
        var newValues: [String: Double] = [:]
        
        let closestPoints = Dictionary(grouping: data, by: { $0.series })
            .mapValues { seriesPoints -> TidyChartDataPoint? in
                seriesPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
            }

        for (series, point) in closestPoints {
            if let point {
                newValues[series] = point.value
            }
        }
        
        self.selectedValues = newValues
    }
    
    private func transformToTidyData() -> [TidyChartDataPoint] {
        var tidyData: [TidyChartDataPoint] = []
        
        let seriesKeys: [String] = [
            "ulBandChart.priceLabel",
            "ulBandChart.upperBandLabel",
            "ulBandChart.lowerBandLabel",
            "ulBandChart.ma20Label"
        ]
        let dataArrays: [[Double]] = [
            chartData.weeklyPrices,
            chartData.upperBand,
            chartData.lowerBand,
            chartData.ma20
        ]

        guard !chartData.weeklyDates.isEmpty else { return [] }

        for i in 0..<chartData.weeklyDates.count {
            let date = date(from: chartData.weeklyDates[i])
            for (j, seriesKey) in seriesKeys.enumerated() {
                if i < dataArrays[j].count {
                     tidyData.append(TidyChartDataPoint(date: date, value: dataArrays[j][i], series: seriesKey))
                }
            }
        }
        return tidyData
    }
}