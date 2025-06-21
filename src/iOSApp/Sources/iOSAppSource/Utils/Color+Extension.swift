import SwiftUI

extension Color {
    public init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// App-specific Color Palette
public struct AppPalette {
    public init() {} // Public initializer
    
    public let price = Color(hex: 0x787878)
    public let trend = Color(hex: 0x708090)
    
    public let plus2SD = Color(hex: 0xD24A93)
    public let plus1SD = Color(hex: 0xF0B8CE)
    public let minus1SD = Color(hex: 0x5B9BD5)
    public let minus2SD = Color(hex: 0x0000FF)

    // For UL Band Chart
    public let upperBand = Color(hex: 0xD24A93)
    public let lowerBand = Color(hex: 0x0000FF)
    public let ma20 = Color(hex: 0x708090)
}

public let AppColors = AppPalette() 