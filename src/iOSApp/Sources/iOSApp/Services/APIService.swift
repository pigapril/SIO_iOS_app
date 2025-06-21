import Foundation

// A generic response structure to handle APIs that wrap the main data
struct APIResponse<T: Decodable>: Decodable {
    let data: T
}

// Specific response structures
struct CategoriesResponse: Decodable {
    let categories: [Category]
}

struct SearchResultsResponse: Decodable {
    let results: [SearchResult]
}


class APIService {
    static let shared = APIService()
    // Make sure this points to your local server's address and port
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
            let dataString = String(data: data, encoding: .utf8) ?? "No data"
            print("HTTP Error: \(response) with data: \(dataString)")
            throw AppError.networkError 
        }
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        // Handle cases where the response body might be empty
        guard !data.isEmpty else {
             throw AppError.unknownError // Or a more specific "emptyData" error
        }

        if expectDataWrapper {
            let wrappedResponse = try decoder.decode(APIResponse<T>.self, from: data)
            return wrappedResponse.data
        } else {
            return try decoder.decode(T.self, from: data)
        }
    }

    // MARK: - Authentication Methods
    
    struct AuthResponse: Decodable {
        let user: User
    }
    
    func verifyGoogleToken(idToken: String) async throws -> User {
        let body = try JSONEncoder().encode(["credential": idToken])
        let response: AuthResponse = try await request(endpoint: "auth/google/verify", method: "POST", body: body, expectDataWrapper: true)
        return response.user
    }

    func logout() async throws {
        _ = try await request(endpoint: "auth/logout", method: "POST", expectDataWrapper: false) as Data
    }
    
    func checkAuthStatus() async throws -> User {
        let response: AuthResponse = try await request(endpoint: "auth/status", method: "GET", expectDataWrapper: true)
        return response.user
    }

    // MARK: - App Data Methods

    func fetchPriceAnalysis(stockCode: String, years: String, backTestDate: String?) async throws -> PriceAnalysisData {
        var queryItems = [
            URLQueryItem(name: "stockCode", value: stockCode),
            URLQueryItem(name: "years", value: years)
        ]
        if let date = backTestDate, !date.isEmpty {
            queryItems.append(URLQueryItem(name: "backTestDate", value: date))
        }
        return try await request(endpoint: "integrated-analysis", queryItems: queryItems, expectDataWrapper: true)
    }

    func fetchMarketSentiment() async throws -> MarketSentimentResponse {
        return try await request(endpoint: "market-sentiment", expectDataWrapper: false)
    }

    func fetchCompositeHistoricalData() async throws -> [HistoricalDataItem] {
       let response: APIResponse<[HistoricalDataItem]> = try await request(endpoint: "composite-historical-data", expectDataWrapper: true)
       return response.data
    }
    
    func fetchIndicatorHistoricalData(indicatorKey: String) async throws -> [IndicatorHistoricalDataItem] {
       let queryItems = [URLQueryItem(name: "indicator", value: indicatorKey)]
       let response: APIResponse<[IndicatorHistoricalDataItem]> = try await request(endpoint: "indicator-history", queryItems: queryItems, expectDataWrapper: true)
       return response.data
    }

    // MARK: - Watchlist Methods

    func fetchCategories() async throws -> [Category] {
        let response: CategoriesResponse = try await request(endpoint: "watchlist/categories", expectDataWrapper: true)
        return response.categories
    }

    func createCategory(name: String) async throws -> Category {
        let body = try JSONEncoder().encode(["name": name])
        return try await request(endpoint: "watchlist/categories", method: "POST", body: body, expectDataWrapper: false)
    }
    
    func updateCategory(id: String, name: String) async throws -> Category {
        let body = try JSONEncoder().encode(["name": name])
        return try await request(endpoint: "watchlist/categories/\(id)", method: "PUT", body: body, expectDataWrapper: false)
    }
    
    func deleteCategory(id: String) async throws {
        _ = try await request(endpoint: "watchlist/categories/\(id)", method: "DELETE", expectDataWrapper: false) as Data
    }

    func addStock(categoryId: String, symbol: String) async throws -> Stock {
    let body = try JSONEncoder().encode(["stockSymbol": symbol])
    
    // 1. 呼叫 request，並期望它解碼外層的 {"data": ...} 結構
    //    所以 expectDataWrapper 應為 true。
    // 2. request<T> 中的 T 現在是我們新定義的 AddStockResponse
    let response: AddStockResponse = try await request(
        endpoint: "watchlist/categories/\(categoryId)/stocks", 
        method: "POST", 
        body: body, 
        expectDataWrapper: true // <<< 設為 true 來處理 {"data": ...}
    )
    
    // 3. 從解碼後的回應中，返回內層的 item (這就是我們需要的 Stock 物件)
    return response.item
}

    func removeStock(categoryId: String, itemId: String) async throws {
        _ = try await request(endpoint: "watchlist/categories/\(categoryId)/stocks/\(itemId)", method: "DELETE", expectDataWrapper: false) as Data
    }

    func searchStocks(keyword: String) async throws -> [SearchResult] {
        let queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        let response: SearchResultsResponse = try await request(endpoint: "watchlist/search", queryItems: queryItems, expectDataWrapper: true)
        return response.results
    }
}