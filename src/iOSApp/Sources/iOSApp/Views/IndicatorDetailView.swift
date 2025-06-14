import SwiftUI
import Charts

struct IndicatorDetail: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let content: String
}

struct IndicatorDetailView: View {
    @StateObject private var viewModel: IndicatorDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    let indicatorKey: String

    init(indicatorKey: String) {
        self.indicatorKey = indicatorKey
        _viewModel = StateObject(wrappedValue: IndicatorDetailViewModel(indicatorKey: indicatorKey))
    }

    private var shortDescription: String {
        NSLocalizedString("marketSentiment.descriptions.\(indicatorKey).shortDescription", comment: "")
    }

    private var sections: [IndicatorDetail] {
        let jsonString = NSLocalizedString("marketSentiment.descriptions.\(indicatorKey).sections", comment: "")
        guard let data = jsonString.data(using: .utf8),
              let decodedSections = try? JSONDecoder().decode([IndicatorDetail].self, from: data) else {
            return []
        }
        return decodedSections
    }
    
    private var indicatorTitle: String {
         NSLocalizedString("indicators.\(indicatorKey)", comment: "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // --- Chart Section ---
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 200)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("圖表載入失敗: \(errorMessage)")
                            .foregroundColor(.red)
                            .frame(height: 200)
                    } else if !viewModel.historicalData.isEmpty {
                        VStack(alignment: .leading) {
                            Text("歷史圖表")
                                .font(.title2.bold())
                            IndicatorHistoricalChart(data: viewModel.historicalData)
                                .frame(height: 250)
                        }
                        .padding(.bottom, 10)
                    }
                    // --- End Chart Section ---
                    
                    Text(shortDescription)
                        .font(.body)

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(section.content)
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(indicatorTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel.historicalData.isEmpty {
                    viewModel.fetchData()
                }
            }
        }
    }
}

struct IndicatorHistoricalChart: View {
    let data: [IndicatorHistoricalDataItem]

    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(by: .value("Series", "指標數值"))
                
                if let percentileRank = item.percentileRank {
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Percentile", percentileRank)
                    )
                    .foregroundStyle(by: .value("Series", "恐懼貪婪分數 (0-100)"))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(NSNumber(value: doubleValue), formatter: NumberFormatter.currency)
                    }
                }
            }
        }
        .chartYAxisLabel("指標數值", position: .leading)
        
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")%")
            }
        }
        .chartYAxisLabel("恐懼貪婪分數", position: .trailing)
    }
}

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
} 