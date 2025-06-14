import SwiftUI
import Combine

@MainActor
class IndicatorDetailViewModel: ObservableObject {
    @Published var historicalData: [IndicatorHistoricalDataItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let indicatorKey: String
    private var cancellables = Set<AnyCancellable>()

    init(indicatorKey: String) {
        self.indicatorKey = indicatorKey
    }

    func fetchData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                self.historicalData = try await APIService.shared.fetchIndicatorHistoricalData(indicatorKey: indicatorKey)
            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "IndicatorDetailViewModel")
            }
            self.isLoading = false
        }
    }
}

// You will need to add this method to your APIService.swift
/*
extension APIService {
    func fetchIndicatorHistoricalData(indicatorKey: String) async throws -> [IndicatorHistoricalDataItem] {
        let url = baseURL.appendingPathComponent("/api/indicator-history")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "indicator", value: indicatorKey)
        ]

        guard let requestUrl = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Or whatever strategy you use globally
        
        return try decoder.decode([IndicatorHistoricalDataItem].self, from: data)
    }
}
*/ 