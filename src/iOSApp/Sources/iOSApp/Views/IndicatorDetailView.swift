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
                    label: NSLocalizedString("indicatorItem.latestDataLabel", bundle: .module, comment: ""),
                    value: viewModel.latestIndicatorData?.value.formatted(.number.precision(.fractionLength(2))) ?? "N/A"
                )
                Divider()
                MetricView(
                    label: NSLocalizedString("indicatorItem.fearGreedScoreLabel", bundle: .module, comment: ""),
                    value: (viewModel.latestIndicatorData?.percentileRank?.formatted(.percent.precision(.fractionLength(0))) ?? "N/A")
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
            
            // The JSON parsing for sections remains the same logic as your original code
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
            Text("Error Loading Data") // Should be localized
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
        // This helper function parses the localized string for sections
        // It's safer to handle potential JSON parsing errors here.
        let jsonString = NSLocalizedString(descriptionSectionsKey, bundle: .module, comment: "JSON array of sections")
        guard let data = jsonString.data(using: .utf8),
              let sections = try? JSONDecoder().decode([IndicatorDetailSection].self, from: data) else {
            return []
        }
        return sections
    }
    
    private static func getTranslationKey(for name: String) -> String {
        // Same mapping as your original code
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
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.title2.bold())
            Text(LocalizedStringKey(label), bundle: .module)
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

// MARK: - Chart View (Restored from original file)
struct IndicatorHistoricalChart: View {
    let data: [IndicatorHistoricalDataItem]

    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(x: .value("Date", item.date), y: .value("Value", item.value))
                    .foregroundStyle(by: .value("Series", "Indicator Value")) // Localize this
                
                if let percentileRank = item.percentileRank {
                    LineMark(x: .value("Date", item.date), y: .value("Percentile", percentileRank))
                        .foregroundStyle(by: .value("Series", "Sentiment Score (0-100)")) // Localize this
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")")
            }
        }
    }
}
