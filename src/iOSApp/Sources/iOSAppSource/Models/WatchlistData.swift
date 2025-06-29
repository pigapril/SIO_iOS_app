import Foundation

// --- MODIFICATION: Made struct and its initializer public ---
public struct Category: Codable, Identifiable {
    public let id: String
    public var name: String
    public var stocks: [Stock]?

    public init(id: String, name: String, stocks: [Stock]?) {
        self.id = id
        self.name = name
        self.stocks = stocks
    }
}

// --- MODIFICATION: Made struct and its initializer public ---
public struct Stock: Codable, Identifiable, Hashable {
    public let id: String
    public let symbol: String
    public let name: String
    public let nameEn: String?
    public let price: Double
    public let change: Double?
    public let changePercent: Double?
    public let logo: String?
    public let analysis: StockAnalysisData?
    
    public init(id: String, symbol: String, name: String, nameEn: String?, price: Double, change: Double?, changePercent: Double?, logo: String?, analysis: StockAnalysisData?) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.nameEn = nameEn
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.logo = logo
        self.analysis = analysis
    }

    // Conformance to Hashable
    public static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// --- MODIFICATION: Made struct and its initializer public ---
public struct StockAnalysisData: Codable, Hashable {
    public let tl_plus_2sd: Double
    public let tl_plus_sd: Double
    public let tl_minus_sd: Double
    public let tl_minus_2sd: Double

    public init(tl_plus_2sd: Double, tl_plus_sd: Double, tl_minus_sd: Double, tl_minus_2sd: Double) {
        self.tl_plus_2sd = tl_plus_2sd
        self.tl_plus_sd = tl_plus_sd
        self.tl_minus_sd = tl_minus_sd
        self.tl_minus_2sd = tl_minus_2sd
    }
}

// --- MODIFICATION: Made struct public ---
public struct SearchResult: Codable, Identifiable, Hashable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let market: String
    
    public init(symbol: String, name: String, market: String) {
        self.symbol = symbol
        self.name = name
        self.market = market
    }

    // Conformance to Hashable
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
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