import Foundation

// A generic response structure to handle APIs that wrap the main data
struct APIResponse<T: Decodable>: Decodable {
    let data: T
}

class APIService {
    static let shared = APIService()
    private let baseURL = URL(string: "http://127.0.0.1:5001/api/")!
    private var csrfToken: String?

    private func request<T: Decodable>(endpoint: String, method: String = "GET", queryItems: [URLQueryItem]? = nil, body: Data? = nil, expectDataWrapper: Bool = true) async throws -> T {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let csrfToken = csrfToken {
            request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-Token")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, let newCsrfToken = httpResponse.allHeaderFields["X-CSRF-Token"] as? String {
            self.csrfToken = newCsrfToken
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // Create a custom error and handle it
            let dataString = String(data: data, encoding: .utf8) ?? "No data"
            print("HTTP Error: \(response) with data: \(dataString)")
            throw AppError.networkError // Placeholder
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if expectDataWrapper {
            let wrappedResponse = try decoder.decode(APIResponse<T>.self, from: data)
            return wrappedResponse.data
        } else {
            return try decoder.decode(T.self, from: data)
        }
    }

    // MARK: - Refactored Methods

    func fetchPriceAnalysis(stockCode: String, years: String, backTestDate: String?) async throws -> PriceAnalysisData {
        var queryItems = [
            URLQueryItem(name: "stockCode", value: stockCode),
            URLQueryItem(name: "years", value: years)
        ]
        if let date = backTestDate {
            queryItems.append(URLQueryItem(name: "backTestDate", value: date))
        }
        return try await request(endpoint: "integrated-analysis", queryItems: queryItems, expectDataWrapper: true)
    }

    func fetchMarketSentiment() async throws -> MarketSentimentResponse {
        return try await request(endpoint: "market-sentiment", expectDataWrapper: false)
    }

    func fetchCompositeHistoricalData() async throws -> CompositeHistoricalDataResponse {
        return try await request(endpoint: "composite-historical-data", expectDataWrapper: false)
    }

    // MARK: - Watchlist Methods

    func fetchCategories() async throws -> [Category] {
        return try await request(endpoint: "watchlist/categories", expectDataWrapper: false)
    }

    func createCategory(name: String) async throws -> Category {
        let body = try JSONEncoder().encode(["name": name])
        return try await request(endpoint: "watchlist/categories", method: "POST", body: body, expectDataWrapper: false)
    }
    
    func updateCategory(id: Int, name: String) async throws -> Category {
        let body = try JSONEncoder().encode(["name": name])
        return try await request(endpoint: "watchlist/categories/\(id)", method: "PUT", body: body, expectDataWrapper: false)
    }
    
    func deleteCategory(id: Int) async throws {
        _ = try await request(endpoint: "watchlist/categories/\(id)", method: "DELETE", expectDataWrapper: false) as Data // Expect empty response
    }

    func addStock(categoryId: Int, symbol: String) async throws -> Stock {
        let body = try JSONEncoder().encode(["stockSymbol": symbol])
        return try await request(endpoint: "watchlist/categories/\(categoryId)/stocks", method: "POST", body: body, expectDataWrapper: false)
    }

    func removeStock(categoryId: Int, itemId: Int) async throws {
        _ = try await request(endpoint: "watchlist/categories/\(categoryId)/stocks/\(itemId)", method: "DELETE", expectDataWrapper: false) as Data
    }

    func searchStocks(keyword: String) async throws -> [SearchResult] {
        let queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        return try await request(endpoint: "watchlist/search", queryItems: queryItems, expectDataWrapper: false)
    }
} 