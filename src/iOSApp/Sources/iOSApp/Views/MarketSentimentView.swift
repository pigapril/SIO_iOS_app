import SwiftUI
import Charts

struct MarketSentimentView: View {
    @StateObject private var viewModel = MarketSentimentViewModel()

    var body: some View {
        ScrollView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text("錯誤: \(errorMessage)")
                        .foregroundColor(.red)
                } else if let sentimentData = viewModel.sentimentData {
                    // Gauge Chart Placeholder
                    GaugeView(value: sentimentData.compositeScore, sentiment: sentimentData.sentiment)
                        .frame(height: 200)
                        .padding()

                    // Indicators
                    DisclosureGroup("市場情緒組成項目") {
                        ForEach(sentimentData.indicators.keys.sorted(), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                Text(sentimentData.indicators[key]!.sentiment)
                                    .foregroundColor(colorForSentiment(sentimentData.indicators[key]!.sentiment))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    
                    // Historical Chart
                    Section(header: Text("歷史數據")) {
                        Picker("時間範圍", selection: $viewModel.selectedTimeRange) {
                            Text("1M").tag("1M")
                            Text("6M").tag("6M")
                            Text("1Y").tag("1Y")
                            Text("3Y").tag("3Y")
                            Text("All").tag("All")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.selectedTimeRange) { newRange in
                            viewModel.filterData(for: newRange)
                        }
                        
                        HistoricalSentimentChart(data: viewModel.filteredHistoricalData)
                            .frame(height: 300)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("市場情緒指數")
        .onAppear {
            viewModel.fetchData()
        }
    }
    
    private func colorForSentiment(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "extreme greed", "greed":
            return .red
        case "extreme fear", "fear":
            return .green
        default:
            return .yellow
        }
    }
}

struct GaugeView: View {
    let value: Double
    let sentiment: String
    
    private var sentimentGradient: Gradient {
        switch sentiment.lowercased() {
        case "extreme greed":
            return Gradient(colors: [.yellow, .red])
        case "greed":
            return Gradient(colors: [.yellow, .orange])
        case "extreme fear":
            return Gradient(colors: [.green, .blue])
        case "fear":
            return Gradient(colors: [.green, .cyan])
        default: // Neutral
            return Gradient(colors: [.gray, .white])
        }
    }

    var body: some View {
        Gauge(value: value, in: 0...100) {
            // The label is not shown in this style, but good for accessibility
        } currentValueLabel: {
            Text(String(format: "%.0f", value))
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(sentimentGradient)
        
        Text(sentiment)
            .font(.title)
            .bold()
            .foregroundColor(colorForSentiment(sentiment))
    }
    
    private func colorForSentiment(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "extreme greed", "greed":
            return .red
        case "extreme fear", "fear":
            return .green
        default:
            return .yellow
        }
    }
}

struct HistoricalSentimentChart: View {
    let data: [HistoricalDataItem]

    private var spyDomain: ClosedRange<Double> {
        let spyData = data.map(\.spyClose)
        let min = spyData.min() ?? 0
        let max = spyData.max() ?? 500
        return min...max
    }

    private var chartContent: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Score", item.compositeScore)
                )
                .foregroundStyle(by: .value("Series", "Score"))
                .symbol(by: .value("Series", "Score"))

                LineMark(
                    x: .value("Date", item.date),
                    y: .value("S&P 500", item.spyClose)
                )
                .foregroundStyle(by: .value("Series", "S&P 500"))
                .interpolationMethod(.catmullRom)
                .symbol(by: .value("Series", "S&P 500"))
            }
        }
    }

    var body: some View {
        chartContent
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartYAxisLabel("Score", position: .leading)
            
            .chartYScale(domain: spyDomain)
            .chartYAxis {
                AxisMarks(position: .trailing)
            }
            .chartYAxisLabel("S&P 500", position: .trailing)
    }
} 