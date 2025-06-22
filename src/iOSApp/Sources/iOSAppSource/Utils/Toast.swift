import SwiftUI

// 1. Make the struct public
public struct Toast: Equatable {
    public var type: ToastType
    public var title: String
    public var message: String? = nil
    public var duration: Double = 3.0

    // When making a struct public, you must also provide a public initializer
    public init(type: ToastType, title: String, message: String? = nil, duration: Double = 3.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }

    public static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message && lhs.type == rhs.type
    }
}

// 2. Make the enum public
public enum ToastType {
    case info
    case success
    case warning
    case error

    public var themeColor: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    public var icon: Image {
        switch self {
        case .info:
            return Image(systemName: "info.circle.fill")
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .warning:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .error:
            return Image(systemName: "xmark.circle.fill")
        }
    }
}