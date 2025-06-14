import Foundation

struct PriceAnalysisData: Codable {
    let dates: [String]
    let prices: [Double]
    let sdAnalysis: StandardDeviationAnalysis
    let weeklyDates: [String]
    let weeklyPrices: [Double]
    let upperBand: [Double]
    let lowerBand: [Double]
    let ma20: [Double]
}

struct StandardDeviationAnalysis: Codable {
    let trendLine: [Double]
    let tl_plus_2sd: [Double]
    let tl_plus_sd: [Double]
    let tl_minus_sd: [Double]
    let tl_minus_2sd: [Double]

    enum CodingKeys: String, CodingKey {
        case trendLine = "trendLine"
        case tl_plus_2sd = "tl_plus_2sd"
        case tl_plus_sd = "tl_plus_sd"
        case tl_minus_sd = "tl_minus_sd"
        case tl_minus_2sd = "tl_minus_2sd"
    }
} 