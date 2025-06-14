import SwiftUI
import Charts

// Card View Modifier
struct CardViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color(.systemBackground)) // Adapts to light/dark mode
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding([.horizontal, .bottom])
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardViewModifier())
    }
}

struct MarketSentimentView: View {
    @StateObject private var viewModel = MarketSentimentViewModel()
    @State private var selectedIndicatorKey: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) { // Set spacing to 0 to let content control it
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text("錯誤: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if let sentimentData = viewModel.sentimentData {
                    VStack(spacing: 25) {
                        // Custom Gauge Chart
                        let score = Double(sentimentData.totalScore) ?? 0
                        SemiCircleGaugeView(
                            value: score,
                            sentiment: viewModel.compositeSentiment,
                            color: viewModel.sentimentColor(for: viewModel.compositeSentiment)
                        )
                        .frame(height: 250)

                        // Historical Chart
                        VStack(spacing: 15) {
                            Text("歷史數據")
                                .font(.title2)
                                .fontWeight(.bold)
                            
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
                        
                        // Indicators
                        DisclosureGroup("市場情緒組成項目") {
                            VStack(spacing: 12) {
                                ForEach(sentimentData.indicators.keys.sorted(), id: \.self) { key in
                                    if let indicator = sentimentData.indicators[key] {
                                        Button(action: {
                                            if let detailKey = viewModel.indicatorKey(forName: key) {
                                                self.selectedIndicatorKey = detailKey
                                            }
                                        }) {
                                            HStack {
                                                Text(key)
                                                    .font(.subheadline)
                                                Spacer()
                                                let sentiment = viewModel.sentiment(for: indicator.percentileRank)
                                                Text(sentiment)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(viewModel.sentimentColor(for: sentiment))
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.secondary)
                                            }
                                            .contentShape(Rectangle()) // Make the whole row tappable
                                        }
                                        .buttonStyle(PlainButtonStyle()) // Use plain style to avoid default button appearance
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        
                        // Last Updated Time
                        Text("最後更新: \(sentimentData.compositeScoreLastUpdate, formatter: Self.dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                    }
                    .cardStyle()
                }
            }
        }
        .sheet(item: $selectedIndicatorKey) { key in
            IndicatorDetailView(indicatorKey: key)
        }
        .background(Color(.systemGroupedBackground)) // Set a background for the whole scroll view
        .navigationTitle("市場情緒指數")
        .onAppear {
            if viewModel.sentimentData == nil {
                viewModel.fetchData()
            }
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// Make String Identifiable to use in .sheet(item:)
extension String: Identifiable {
    public var id: String { self }
}

struct SemiCircleGaugeView: View {
    let value: Double
    let sentiment: String
    let color: Color

    var body: some View {
        ZStack {
            // Background semi-circle
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 35, lineCap: .round))
            
            // Value semi-circle
            Circle()
                .trim(from: 0.5, to: 0.5 + (value / 100.0) / 2.0)
                .stroke(color, style: StrokeStyle(lineWidth: 35, lineCap: .round))
                .animation(.easeInOut(duration: 1.0), value: value)

            // Center Text
            VStack {
                Text(String(format: "%.0f", value))
                    .font(.system(size: 70, weight: .bold))
                Text(sentiment)
                    .font(.title2.bold())
            }
            .offset(y: -40) // Move text up

            // Min & Max Labels
            HStack {
                Text("極度恐懼")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
                Text("極度貪婪")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .offset(y: 40) // Move labels down
        }
        .padding(.horizontal, 20)
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

    var body: some View {
        VStack {
            ZStack {
                // Chart for Composite Score on the left axis
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Score", item.compositeScore)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYAxisLabel("綜合分數", position: .leading)

                // Chart for S&P 500 on the right axis
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("S&P 500", item.spyClose)
                        )
                        .foregroundStyle(.gray.opacity(0.8))
                    }
                }
                .chartYScale(domain: spyDomain)
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine().foregroundStyle(.clear) // Hide grid lines from this axis
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYAxisLabel("S&P 500 價格", position: .trailing)
            }
            
            // Custom Legend
            HStack(spacing: 20) {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(.blue)
                        .frame(width: 15, height: 3)
                    Text("綜合分數")
                        .font(.caption)
                }
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(.gray.opacity(0.8))
                        .frame(width: 15, height: 3)
                    Text("S&P 500")
                        .font(.caption)
                }
            }
            .padding(.top, 5)
        }
    }
} 