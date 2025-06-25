// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV1/src/iOSApp/Sources/iOSAppSource/Views/PriceAnalysisView.swift

import SwiftUI
import Charts

struct PriceAnalysisView: View {
    @StateObject private var viewModel: PriceAnalysisViewModel
    @State private var activeChart: ChartType = .standardDeviation
    @State private var isAdvancedQuery: Bool = false
    
    init(initialStockCode: String? = nil, initialYears: String? = nil) {
        _viewModel = StateObject(wrappedValue: PriceAnalysisViewModel(
            stockCode: initialStockCode ?? "SPY",
            years: initialYears ?? "3.5"
        ))
    }
    
    // 使用翻譯鍵
    enum ChartType: String, CaseIterable {
        case standardDeviation = "priceAnalysis.chart.tabs.sd"
        case ulBand = "priceAnalysis.chart.tabs.ulband"

        var localized: LocalizedStringKey {
            return LocalizedStringKey(self.rawValue)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                queryCard
                chartContainer
            }
            .padding()
        }
        .navigationTitle(Text("priceAnalysis.pageTitle", bundle: .module))
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if viewModel.chartData == nil {
                viewModel.fetchStockData()
            }
        }
    }
    
    // MARK: - Query Card
    private var queryCard: some View {
        let stockCodePlaceholder = NSLocalizedString("priceAnalysis.form.stockCodePlaceholder", bundle: .module, comment: "")
        let yearsPlaceholder = NSLocalizedString("priceAnalysis.form.yearsPlaceholder", bundle: .module, comment: "")

        return VStack(spacing: 15) {
            Text("priceAnalysis.form.title", bundle: .module)
                .font(.headline)
            
            HStack {
                Text("priceAnalysis.form.stockCodeLabel", bundle: .module).frame(width: 100, alignment: .leading)
                TextField(stockCodePlaceholder, text: $viewModel.stockCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
            
            if !isAdvancedQuery {
                HStack {
                    Text("priceAnalysis.form.analysisPeriodLabel", bundle: .module).frame(width: 100, alignment: .leading)
                    Picker(selection: $viewModel.analysisPeriod, label: Text("priceAnalysis.form.analysisPeriodLabel", bundle: .module)) {
                        Text("priceAnalysis.form.periodShort", bundle: .module).tag(PriceAnalysisViewModel.AnalysisPeriod.short)
                        Text("priceAnalysis.form.periodMedium", bundle: .module).tag(PriceAnalysisViewModel.AnalysisPeriod.medium)
                        Text("priceAnalysis.form.periodLong", bundle: .module).tag(PriceAnalysisViewModel.AnalysisPeriod.long)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            if isAdvancedQuery {
                HStack {
                    Text("priceAnalysis.form.analysisPeriodLabel", bundle: .module).frame(width: 100, alignment: .leading)
                    TextField(yearsPlaceholder, text: $viewModel.years)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                DatePicker(
                    selection: Binding(
                        get: { viewModel.backTestDate ?? Date() },
                        set: { viewModel.backTestDate = $0 }
                    ),
                    displayedComponents: .date,
                    label: { Text("priceAnalysis.form.backTestDateLabel", bundle: .module) }
                )
            }
            
            Toggle(isOn: $isAdvancedQuery.animation()) {
                Text(isAdvancedQuery ? "priceAnalysis.form.switchToSimple" : "priceAnalysis.form.switchToAdvanced", bundle: .module)
            }
            
            Button(action: {
                viewModel.fetchStockData()
            }) {
                Text(viewModel.isLoading ? "priceAnalysis.form.buttonAnalyzing" : "priceAnalysis.form.buttonStartAnalysis", bundle: .module)
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
    
    // MARK: - Hot Searches
    private var hotSearchesSection: some View {
        VStack {
            Text("priceAnalysis.hotSearches.title", bundle: .module)
                .font(.subheadline).bold()
            HStack {
                Button("TSLA") { viewModel.stockCode = "TSLA"; viewModel.fetchStockData() }
                Button("NVDA") { viewModel.stockCode = "NVDA"; viewModel.fetchStockData() }
                Button("AAPL") { viewModel.stockCode = "AAPL"; viewModel.fetchStockData() }
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Chart Container
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
                        Text(type.localized, bundle: .module).tag(type)
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
                Text("priceAnalysis.prompt.enterSymbol", bundle: .module)
                    .foregroundColor(.secondary)
                    .frame(height: 350)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Analysis Result Header
    private func analysisResultHeader(result: (price: Double, sentimentKey: String)) -> some View {
        HStack(spacing: 20) {
            VStack {
                Text("priceAnalysis.result.stockCode", bundle: .module)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.stockCode.uppercased())
                    .font(.headline)
            }
            VStack {
                Text("priceAnalysis.result.stockPrice", bundle: .module)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.2f", result.price))
                    .font(.headline)
            }
            VStack {
                Text("priceAnalysis.result.marketSentiment", bundle: .module)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(LocalizedStringKey(result.sentimentKey), bundle: .module)
                    .font(.headline)
                    .foregroundColor(sentimentColor(sentimentKey: result.sentimentKey))
            }
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

// MARK: - Sub-charts

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
                let trendLineText = NSLocalizedString(trendLineKey, bundle: .module, comment: "")
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Trend", point.value)
                )
                .foregroundStyle(AppColors.trend)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                .annotation(position: .top, alignment: .leading) {
                    Text(trendLineText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            if let selectedDate {
                RuleMark(x: .value("Date", selectedDate))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
            }
        }
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
                    let seriesText = NSLocalizedString(seriesKey, bundle: .module, comment: "")
                    HStack {
                        Circle()
                            .fill(seriesKeyMap[seriesKey] ?? AppColors.trend)
                            .frame(width: 8, height: 8)
                        Text(seriesText)
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
                    let seriesText = NSLocalizedString(seriesKey, bundle: .module, comment: "")
                    HStack {
                        Circle()
                            .fill(seriesKeyMap[seriesKey]!)
                            .frame(width: 8, height: 8)
                        Text(seriesText)
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