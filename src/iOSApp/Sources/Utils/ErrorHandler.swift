import Foundation

enum AppError: String, Error {
    case networkError = "NETWORK_ERROR"
    case timeoutError = "TIMEOUT_ERROR"
    case googleAuthCancelled = "GOOGLE_AUTH_CANCELLED"
    case googleAuthPopupBlocked = "GOOGLE_AUTH_POPUP_BLOCKED"
    case turnstileRequired = "TURNSTILE_REQUIRED"
    case turnstileError = "TURNSTILE_ERROR"
    case turnstileExpired = "TURNSTILE_EXPIRED"
    case unknownError = "UNKNOWN_ERROR"

    // Custom initializer to determine error from various sources
    init(error: Error) {
        let nsError = error as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorTimedOut:
                self = .timeoutError
            case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
                self = .networkError
            default:
                self = .unknownError
            }
        // Add other domain checks if necessary
        default:
            self = .unknownError
        }
    }
}

class ErrorHandler {
    static func handle(error: Error, component: String = "Unknown") {
        let appError = AppError(error: error)
        
        Analytics.logError(
            status: (error as NSError).code,
            errorCode: appError.rawValue,
            message: "[\(appError.rawValue)] \(error.localizedDescription)",
            component: component,
            path: "" // Should be determined by the view
        )

        // Here you would typically show an alert to the user
        // For now, we'll just print to the console
        print("Error handled: \(appError.rawValue), component: \(component)")
    }
} 