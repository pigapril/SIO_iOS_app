import SwiftUI
import Charts

// Main Detail View
struct IndicatorDetailView: View {
    @StateObject private var viewModel: IndicatorDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Translation keys
    private let indicatorTitleKey: String
    private let descriptionShortKey: String
    private let descriptionSectionsKey: String

    init(indicatorName: String) {
        let key = Self.getTranslationKey(for: indicatorName)
        self.indicatorTitleKey = "indicators.\(key)"
        self.descriptionShortKey = "marketSentiment.descriptions.\(key).shortDescription"
        self.descriptionSectionsKey = "marketSentiment.descriptions.\(key).sections"
        _viewModel = StateObject(wrappedValue: IndicatorDetailViewModel(indicatorKey: indicatorName))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else {
                        summaryView
                        chartView
                        descriptionView
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text(LocalizedStringKey(indicatorTitleKey), bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() } // "Done" should be localized
                }
            }
            .onAppear(perform: viewModel.fetchData)
        }
    }

    // MARK: - Subviews

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("indicatorItem.latestDataLabel", bundle: .module)
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                MetricView(
                    labelKey: "indicatorItem.latestDataLabel",
                    value: viewModel.latestIndicatorData?.value.formatted(.number.precision(.fractionLength(2))) ?? "N/A"
                )
                Divider()
                MetricView(
                    labelKey: "indicatorItem.fearGreedScoreLabel",
                    value: viewModel.latestIndicatorData?.percentileRank?.formatted(.number.precision(.fractionLength(0))) ?? "N/A"
                )
            }
        }
        .cardStyle()
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                ForEach(IndicatorDetailViewModel.TimeRangeOption.allCases) { option in
                    Text(LocalizedStringKey(option.localizedKey), bundle: .module).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedTimeRange) { newRange in
                viewModel.filterData(for: newRange)
            }

            IndicatorHistoricalChart(data: viewModel.filteredHistoricalData)
                .frame(height: 250)
        }
        .cardStyle()
    }

    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(LocalizedStringKey(descriptionShortKey), bundle: .module)
                .font(.body)
                .foregroundColor(.secondary)
            
            ForEach(getSections()) { section in
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.title).font(.headline)
                    Text(section.content).font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }

    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Error Loading Data")
                .font(.headline)
                .padding(.top, 4)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Helper Functions

    private func getSections() -> [IndicatorDetailSection] {
        let jsonString = NSLocalizedString(descriptionSectionsKey, bundle: .module, comment: "JSON array of sections")
        guard let data = jsonString.data(using: .utf8),
              let sections = try? JSONDecoder().decode([IndicatorDetailSection].self, from: data) else {
            return []
        }
        return sections
    }
    
    private static func getTranslationKey(for name: String) -> String {
        let map = [
            "AAII Bull-Bear Spread": "aaiiSpread", "CBOE Put/Call Ratio 5-Day Avg": "cboeRatio",
            "Market Momentum": "marketMomentum", "VIX MA50": "vixMA50",
            "Safe Haven Demand": "safeHaven", "Junk Bond Spread": "junkBond",
            "S&P 500 COT Index": "cotIndex", "NAAIM Exposure Index": "naaimIndex"
        ]
        return map[name] ?? "unknown"
    }
}

// Reusable Metric View for the summary
struct MetricView: View {
    let labelKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.title2.bold())
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Placeholder for section data structure
struct IndicatorDetailSection: Codable, Identifiable {
    var id: String { title }
    let title: String
    let content: String
}

// MARK: - Chart View (Corrected)
struct IndicatorHistoricalChart: View {
    let data: [IndicatorHistoricalDataItem]

    private var valueDomain: ClosedRange<Double> {
        let values = data.map(\.value)
        guard let min = values.min(), let max = values.max(), min != max else {
            return (values.first ?? 0)...((values.first ?? 0) + 1)
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Chart for Percentile Rank (Sentiment Score) on the left
                Chart {
                    ForEach(data) { item in
                        if let rank = item.percentileRank {
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Sentiment Score", rank)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisTick()
                        // **FIXED**: Using a closure with String(format:) for clarity
                        AxisValueLabel {
                            Text(String(format: "%.0f", value.as(Double.self) ?? 0))
                        }
                    }
                }
                .chartYAxisLabel(position: .leading, alignment: .center) {
                    Text("Sentiment Score", bundle: .module)
                }

                // Chart for raw Indicator Value on the right
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Indicator Value", item.value)
                        )
                        .foregroundStyle(Color.orange)
                    }
                }
                .chartYScale(domain: valueDomain)
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick()
                        // **FIXED**: Using a closure with String(format:) for clarity
                        AxisValueLabel {
                             Text(String(format: "%.2f", value.as(Double.self) ?? 0))
                        }
                    }
                }
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                     Text("Indicator Value", bundle: .module)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartLegend(.hidden)
            
            // Custom Legend
            HStack(spacing: 20) {
                legendItem(color: .orange, label: "Indicator Value")
                legendItem(color: .blue, label: "Sentiment Score (0-100)")
            }
            .padding(.top, 5)
        }
    }

    private func legendItem(color: Color, label: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(color).frame(width: 15, height: 3)
            Text(label, bundle: .module).font(.caption).foregroundColor(.secondary)
        }
    }
}
