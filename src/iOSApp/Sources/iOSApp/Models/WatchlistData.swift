import Foundation

struct Category: Codable, Identifiable {
    let id: Int
    var name: String
    var stocks: [Stock]
}

struct Stock: Codable, Identifiable {
    let id: Int
    let symbol: String
    let name: String
    let lastPrice: Double
    let change: Double
    let changePercent: Double
    // Add other properties as needed from the API response
}

struct SearchResult: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
} 