import Foundation

struct Category: Codable, Identifiable {
    let id: String
    var name: String
    var stocks: [Stock]
}

struct Stock: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let price: Double
    let change: Double?
    let changePercent: Double?
    // Add other properties as needed from the API response
}

struct SearchResult: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
} 