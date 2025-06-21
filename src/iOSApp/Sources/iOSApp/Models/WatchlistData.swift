import Foundation

struct Category: Codable, Identifiable {
    let id: String
    var name: String
    var stocks: [Stock]
}

struct Stock: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let nameEn: String?
    let price: Double
    let change: Double?
    let changePercent: Double?
    let logo: String?
    let analysis: StockAnalysisData?
    
    // Conformance to Hashable
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct StockAnalysisData: Codable, Hashable {
    let tl_plus_2sd: Double
    let tl_plus_sd: Double
    let tl_minus_sd: Double
    let tl_minus_2sd: Double
}

struct SearchResult: Codable, Identifiable, Hashable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let market: String
    
    // Conformance to Hashable
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


struct AddStockResponse: Decodable {
    let item: Stock
}

struct CreateCategoryResponse: Decodable {
    let category: Category
}

struct UpdateCategoryResponse: Decodable {
    let category: Category
}