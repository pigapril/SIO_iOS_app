// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Services/APIService.swift

import Foundation

private enum APIConfig {
    static let baseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseUrl") as? String else {
            fatalError("錯誤：ApiBaseUrl 未在 Info.plist 中設定！")
        }
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

struct AppleVerificationRequest: Codable {
    let identityToken: String
    let fullName: FullNameRequest?
    let email: String?
}

struct FullNameRequest: Codable {
    let givenName: String?
    let familyName: String?
}
// MARK: - Hot Searches Data Structures
struct HotSearchItem: Codable, Identifiable {
    let keyword: String
    var id: String { keyword }
}

struct HotSearchesData: Codable {
    let top_searches: [HotSearchItem]
}


public class APIService {
    public static let shared = APIService()
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

            if let date = iso8601FullFormatter.date(from: dateStr) {
                return date
            }
            if let date = yyyyMMddFormatter.date(from: dateStr) {
                return date
            }
            
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
        _ = try await request(endpoint: "auth/logout", method: "POST", expectDataWrapper: false) as StatusResponse
    }
    
    func checkAuthStatus() async throws -> User {
        let response: AuthResponse = try await request(endpoint: "auth/status", method: "GET", expectDataWrapper: true)
        return response.user
    }

    func verifyAppleToken(idToken: String, fullName: PersonNameComponents?, email: String?) async throws -> User {
        let nameRequest = FullNameRequest(
            givenName: fullName?.givenName,
            familyName: fullName?.familyName
        )
        let requestBody = AppleVerificationRequest(
            identityToken: idToken,
            fullName: nameRequest,
            email: email
        )
        let body = try JSONEncoder().encode(requestBody)
        let response: AuthResponse = try await request(
            endpoint: "auth/apple/verify",
            method: "POST",
            body: body,
            expectDataWrapper: true
        )
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
        if let source = source {
            queryItems.append(URLQueryItem(name: "source", value: source))
        }
        
        return try await request(endpoint: "integrated-analysis", queryItems: queryItems, expectDataWrapper: true)
    }

    func fetchHotSearches() async throws -> [HotSearchItem] {
        let response: HotSearchesData = try await request(endpoint: "hot-searches", expectDataWrapper: true)
        return response.top_searches
    }

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

    // +++ NEW METHOD for fetching dashboard preview +++
    /// Fetches a lightweight, pre-sorted list of stocks for the dashboard preview.
    func fetchWatchlistPreview() async throws -> [Stock] {
        // The backend returns an array of stocks directly in the 'data' field.
        // We expect the backend response to be: { status: "success", data: [Stock, Stock, ...] }
        return try await request(endpoint: "watchlist/dashboard-preview", expectDataWrapper: true)
    }

    // This full fetch is now only used by the dedicated WatchlistView
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