// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Services/APIService.swift

import Foundation

private enum APIConfig {
    static let baseURL: URL = {
        // 從 Info.plist 中讀取我們設定的 "ApiBaseUrl"
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseUrl") as? String else {
            fatalError("錯誤：ApiBaseUrl 未在 Info.plist 中設定！")
        }
        // 確保 URL 字串是有效的
        guard let url = URL(string: urlString) else {
            fatalError("錯誤：Info.plist 中的 URL 字串無效: \(urlString)")
        }
        return url
    }()
}

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

struct StatusResponse: Decodable {
    let status: String
}

// New structures for decoding backend error responses
struct BackendErrorData: Decodable {
    let errorCode: String
    let message: String
    let stack: String?
}

struct BackendErrorResponse: Decodable {
    let status: String
    let data: BackendErrorData
}

// MARK: - Hot Searches Data Structures
// New structs to decode the response from /api/hot-searches
struct HotSearchItem: Codable, Identifiable {
    let keyword: String
    var id: String { keyword }
}

struct HotSearchesData: Codable {
    let top_searches: [HotSearchItem]
}
// MARK: - End Hot Searches Data Structures


class APIService {
    static let shared = APIService()
    private let baseURL = APIConfig.baseURL
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

            if let backendErrorResponse = try? JSONDecoder().decode(BackendErrorResponse.self, from: data) {
                throw AppError.backendError(code: backendErrorResponse.data.errorCode, message: backendErrorResponse.data.message)
            } else {
                print("Failed to decode backend error response from raw data: \(dataString)")
                throw AppError.unknownError
            }
        }
        
        let decoder = JSONDecoder()
        let iso8601FullFormatter = ISO8601DateFormatter()
        iso8601FullFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
        let container = try decoder.singleValueContainer()
        let dateStr = try container.decode(String.self)

        // 依序嘗試多種格式
        if let date = iso8601FullFormatter.date(from: dateStr) {
            // 嘗試完整的 ISO8601 格式 (例如: "2025-06-29T10:00:00.123Z")
            return date
        }
        if let date = yyyyMMddFormatter.date(from: dateStr) {
            // 嘗試只有日期的格式 (例如: "2025-06-29")
            return date
        }
        
        // 如果所有格式都失敗，才拋出錯誤
        throw DecodingError.dataCorruptedError(in: container,
            debugDescription: "無法解碼日期字串 '\(dateStr)'，它不符合任何預期的格式。")
        })

        guard !data.isEmpty else {
             throw AppError.unknownError
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

     func fetchPriceAnalysis(stockCode: String, years: String, backTestDate: String?, source: String? = nil) async throws -> PriceAnalysisData {
        var queryItems = [
            URLQueryItem(name: "stockCode", value: stockCode),
            URLQueryItem(name: "years", value: years)
        ]
        if let date = backTestDate, !date.isEmpty {
            queryItems.append(URLQueryItem(name: "backTestDate", value: date))
        }
        // 如果提供了 source，就將其添加到查詢參數中
        if let source = source {
            queryItems.append(URLQueryItem(name: "source", value: source))
        }
        
        return try await request(endpoint: "integrated-analysis", queryItems: queryItems, expectDataWrapper: true)
    }

    // MARK: - Hot Searches Method
    /// Fetches the list of hot search stock symbols from the server.
    /// This corresponds to the `/api/hot-searches` endpoint.
    func fetchHotSearches() async throws -> [HotSearchItem] {
        let response: HotSearchesData = try await request(endpoint: "hot-searches", expectDataWrapper: true)
        return response.top_searches
    }
    // MARK: - End Hot Searches Method

    func fetchMarketSentiment() async throws -> MarketSentimentResponse {
        return try await request(endpoint: "market-sentiment", expectDataWrapper: false)
    }

    func fetchCompositeHistoricalData() async throws -> [HistoricalDataItem] {
       return try await request(endpoint: "composite-historical-data", expectDataWrapper: false)
    }
    
    func fetchIndicatorHistoricalData(indicatorKey: String) async throws -> [IndicatorHistoricalDataItem] {
       let queryItems = [URLQueryItem(name: "indicator", value: indicatorKey)]
       return try await request(endpoint: "indicator-history", queryItems: queryItems, expectDataWrapper: false)
    }

    // MARK: - Watchlist Methods

    func fetchCategories() async throws -> [Category] {
        let response: CategoriesResponse = try await request(endpoint: "watchlist/categories", expectDataWrapper: true)
        return response.categories
    }

    func createCategory(name: String) async throws -> Category {
        let body = try JSONEncoder().encode(["name": name])
        let response: CreateCategoryResponse = try await request(
            endpoint: "watchlist/categories",
            method: "POST",
            body: body,
            expectDataWrapper: true
        )
        return response.category
    }
    
    func updateCategory(id: String, name: String) async throws -> Category {
        let body = try JSONEncoder().encode(["name": name])
        let response: UpdateCategoryResponse = try await request(
            endpoint: "watchlist/categories/\(id)",
            method: "PUT",
            body: body,
            expectDataWrapper: true
        )
        return response.category
    }
    
    func deleteCategory(id: String) async throws {
        _ = try await request(endpoint: "watchlist/categories/\(id)", method: "DELETE", expectDataWrapper: false) as StatusResponse
    }

    func addStock(categoryId: String, symbol: String) async throws -> Stock {
        let body = try JSONEncoder().encode(["stockSymbol": symbol])
        let response: AddStockResponse = try await request(
            endpoint: "watchlist/categories/\(categoryId)/stocks",
            method: "POST",
            body: body,
            expectDataWrapper: true
        )
        return response.item
    }

    func removeStock(categoryId: String, itemId: String) async throws {
        _ = try await request(endpoint: "watchlist/categories/\(categoryId)/stocks/\(itemId)", method: "DELETE", expectDataWrapper: false) as StatusResponse
    }

    func searchStocks(keyword: String) async throws -> [SearchResult] {
        let queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        let response: SearchResultsResponse = try await request(endpoint: "watchlist/search", queryItems: queryItems, expectDataWrapper: true)
        return response.results
    }
}