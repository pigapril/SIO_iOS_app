import SwiftUI
import Charts

struct PriceAnalysisView: View {
    @StateObject private var viewModel = PriceAnalysisViewModel()

    var body: some View {
        Form {
            Section(header: Text("查詢參數")) {
                TextField("股票代碼", text: $viewModel.stockCode)
                    .autocapitalization(.allCharacters)
                TextField("分析年份", text: $viewModel.years)
                    .keyboardType(.decimalPad)
                DatePicker(
                    "回測日期 (可選)",
                    selection: Binding(
                        get: { viewModel.backTestDate ?? Date() },
                        set: { viewModel.backTestDate = $0 }
                    ),
                    displayedComponents: .date
                )
            }

            Section {
                Button(action: {
                    viewModel.fetchStockData()
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("開始分析")
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text("錯誤: \(errorMessage)")
                        .foregroundColor(.red)
                }
            }

            if let result = viewModel.analysisResult {
                Section(header: Text("分析結果")) {
                    HStack {
                        Text("最新價格:")
                        Spacer()
                        Text(String(format: "%.2f", result.price))
                    }
                    HStack {
                        Text("市場情緒:")
                        Spacer()
                        Text(result.sentiment)
                    }
                }
            }

            if let chartData = viewModel.chartData {
                Section(header: Text("標準差分析圖")) {
                    PriceStandardDeviationChart(chartData: chartData)
                        .frame(height: 300)
                }
                Section(header: Text("UL Band 圖")) {
                    ULBandChart(chartData: chartData)
                        .frame(height: 300)
                }
            }
        }
        .navigationTitle("價格標準差分析")
        .onAppear {
            viewModel.fetchStockData() // Fetch data on appear
        }
    }
}

struct PriceStandardDeviationChart: View {
    let chartData: PriceAnalysisData
    
    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private func date(from string: String) -> Date {
        return isoDateFormatter.date(from: string) ?? Date()
    }

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
        let trendLine: Double
        let plus2sd: Double
        let plus1sd: Double
        let minus1sd: Double
        let minus2sd: Double
    }

    var body: some View {
        let dataPoints = chartData.dates.indices.map { index -> ChartDataPoint in
            return ChartDataPoint(
                date: date(from: chartData.dates[index]),
                price: chartData.prices[index],
                trendLine: chartData.sdAnalysis.trendLine[index],
                plus2sd: chartData.sdAnalysis.tl_plus_2sd[index],
                plus1sd: chartData.sdAnalysis.tl_plus_sd[index],
                minus1sd: chartData.sdAnalysis.tl_minus_sd[index],
                minus2sd: chartData.sdAnalysis.tl_minus_2sd[index]
            )
        }
        
        Chart(dataPoints) { point in
            LineMark(x: .value("Date", point.date), y: .value("Price", point.price))
                .foregroundStyle(.gray)
                .symbol(Circle().strokeBorder(lineWidth: 1.5))
            
            LineMark(x: .value("Date", point.date), y: .value("Trend", point.trendLine))
                .foregroundStyle(.gray)
            
            LineMark(x: .value("Date", point.date), y: .value("+2 SD", point.plus2sd))
                .foregroundStyle(.pink)

            LineMark(x: .value("Date", point.date), y: .value("+1 SD", point.plus1sd))
                .foregroundStyle(.red)

            LineMark(x: .value("Date", point.date), y: .value("-1 SD", point.minus1sd))
                .foregroundStyle(.blue)

            LineMark(x: .value("Date", point.date), y: .value("-2 SD", point.minus2sd))
                .foregroundStyle(.purple)
        }
        .chartXAxis {
            AxisMarks(preset: .automatic, values: .automatic)
        }
        .chartYAxis {
            AxisMarks(preset: .automatic, values: .automatic)
        }
    }
}

struct ULBandChart: View {
    let chartData: PriceAnalysisData
    
    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func date(from string: String) -> Date {
        return isoDateFormatter.date(from: string) ?? Date()
    }

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
        let upperBand: Double
        let lowerBand: Double
        let ma20: Double
    }

    var body: some View {
        let dataPoints = chartData.weeklyDates.indices.map { index -> ChartDataPoint in
            return ChartDataPoint(
                date: date(from: chartData.weeklyDates[index]),
                price: chartData.weeklyPrices[index],
                upperBand: chartData.upperBand[index],
                lowerBand: chartData.lowerBand[index],
                ma20: chartData.ma20[index]
            )
        }
        
        Chart(dataPoints) { point in
            LineMark(x: .value("Date", point.date), y: .value("Price", point.price))
                .foregroundStyle(.blue)
                .symbol(Circle().strokeBorder(lineWidth: 1.5))

            LineMark(x: .value("Date", point.date), y: .value("Upper Band", point.upperBand))
                .foregroundStyle(.green)

            LineMark(x: .value("Date", point.date), y: .value("Lower Band", point.lowerBand))
                .foregroundStyle(.red)

            LineMark(x: .value("Date", point.date), y: .value("MA20", point.ma20))
                .foregroundStyle(.orange)
        }
        .chartXAxis {
            AxisMarks(preset: .automatic, values: .automatic)
        }
        .chartYAxis {
            AxisMarks(preset: .automatic, values: .automatic)
        }
    }
} 