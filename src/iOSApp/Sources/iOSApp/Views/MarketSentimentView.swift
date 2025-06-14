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
                            HStack {
                                Text("歷史數據")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Menu {
                                    Button("1個月", action: { viewModel.filterData(for: "1M") })
                                    Button("3個月", action: { viewModel.filterData(for: "3M") })
                                    Button("6個月", action: { viewModel.filterData(for: "6M") })
                                    Button("1年", action: { viewModel.filterData(for: "1Y") })
                                    Button("3年", action: { viewModel.filterData(for: "3Y") })
                                    Button("5年", action: { viewModel.filterData(for: "5Y") })
                                    Button("全部", action: { viewModel.filterData(for: "All") })
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedTimeRange.displayString)
                                        Image(systemName: "chevron.down")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                            
                            HistoricalSentimentChart(data: viewModel.filteredHistoricalData)
                                .frame(height: 300)
                            
                            if let range = viewModel.dateRange, let selected = viewModel.selectedDate {
                                VStack {
                                    Slider(
                                        value: Binding(
                                            get: { selected.timeIntervalSinceReferenceDate },
                                            set: { viewModel.selectedDate = Date(timeIntervalSinceReferenceDate: $0) }
                                        ),
                                        in: range.lowerBound.timeIntervalSinceReferenceDate...range.upperBound.timeIntervalSinceReferenceDate
                                    )
                                    .onChange(of: viewModel.selectedDate) { _ in
                                        viewModel.filterDataBySlider()
                                    }
                                    
                                    HStack {
                                        Text(range.lowerBound, style: .date)
                                        Spacer()
                                        Text(range.upperBound, style: .date)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
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
    
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    var body: some View {
        VStack {
            ZStack {
                // Chart for Composite Score
                Chart {
                    ForEach(data) { item in
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Score", item.compositeScore)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                stops: [
                                    .init(color: colorFromHex("D24A93").opacity(0.6), location: 0.0),
                                    .init(color: colorFromHex("F0B8CE").opacity(0.5), location: 0.25),
                                    .init(color: colorFromHex("708090").opacity(0.4), location: 0.5),
                                    .init(color: colorFromHex("5B9BD5").opacity(0.3), location: 0.75),
                                    .init(color: .blue.opacity(0.0), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Score", item.compositeScore)
                        )
                        .foregroundStyle(colorFromHex("9D00FF"))
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxisLabel("綜合分數", position: .leading, alignment: .center)

                // Chart for S&P 500
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
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick()
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel(doubleValue.formatted(.number.precision(.fractionLength(0))))
                        }
                    }
                }
                .chartYAxisLabel("S&P 500 價格", position: .trailing, alignment: .center)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            
            // Custom Legend
            HStack(spacing: 20) {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(colorFromHex("9D00FF"))
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

private extension ClosedRange where Bound == Double {
    var formattedValues: [Double] {
        let strideBy = (upperBound - lowerBound) / 4
        guard strideBy > 0 else { return [lowerBound, upperBound] }
        let a = Array(stride(from: lowerBound, to: upperBound, by: strideBy))
        return a + [upperBound]
    }
} 