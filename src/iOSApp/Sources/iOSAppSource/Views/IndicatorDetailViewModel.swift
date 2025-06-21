import SwiftUI
import Combine

@MainActor
class IndicatorDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var filteredHistoricalData: [IndicatorHistoricalDataItem] = []
    @Published var latestIndicatorData: IndicatorHistoricalDataItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: TimeRangeOption = .oneYear

    // MARK: - Private Properties
    private let indicatorKey: String
    private var fullHistoricalData: [IndicatorHistoricalDataItem] = []
    private var cancellables = Set<AnyCancellable>()

    // Enum for type-safe time range selection
    enum TimeRangeOption: String, CaseIterable, Identifiable {
        case oneMonth, threeMonths, sixMonths, oneYear, twoYears, fiveYears, all
        
        var id: String { self.rawValue }
        
        var localizedKey: String {
            switch self {
            case .oneMonth: "timeRangeSelector.month1"
            case .threeMonths: "timeRangeSelector.month3"
            case .sixMonths: "timeRangeSelector.month6"
            case .oneYear: "timeRangeSelector.year1"
            case .twoYears: "timeRangeSelector.year2"
            case .fiveYears: "timeRangeSelector.year5"
            case .all: "All" // "All" likely doesn't need translation
            }
        }
    }

    init(indicatorKey: String) {
        self.indicatorKey = indicatorKey
    }

    // MARK: - Data Fetching and Filtering
    func fetchData() {
        guard fullHistoricalData.isEmpty else { return } // Fetch only once
        
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await APIService.shared.fetchIndicatorHistoricalData(indicatorKey: indicatorKey)
                self.fullHistoricalData = data
                self.latestIndicatorData = data.last
                self.filterData(for: self.selectedTimeRange) // Apply initial filter
            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "IndicatorDetailViewModel")
            }
            self.isLoading = false
        }
    }

    func filterData(for range: TimeRangeOption) {
        self.selectedTimeRange = range
        guard !fullHistoricalData.isEmpty else {
            filteredHistoricalData = []
            return
        }

        let calendar = Calendar.current
        guard let endDate = fullHistoricalData.last?.date else { return }
        var startDate: Date?

        switch range {
        case .oneMonth: startDate = calendar.date(byAdding: .month, value: -1, to: endDate)
        case .threeMonths: startDate = calendar.date(byAdding: .month, value: -3, to: endDate)
        case .sixMonths: startDate = calendar.date(byAdding: .month, value: -6, to: endDate)
        case .oneYear: startDate = calendar.date(byAdding: .year, value: -1, to: endDate)
        case .twoYears: startDate = calendar.date(byAdding: .year, value: -2, to: endDate)
        case .fiveYears: startDate = calendar.date(byAdding: .year, value: -5, to: endDate)
        case .all: startDate = nil // No start date for all data
        }

        if let start = startDate {
            self.filteredHistoricalData = fullHistoricalData.filter { $0.date >= start }
        } else {
            self.filteredHistoricalData = fullHistoricalData
        }
    }
}