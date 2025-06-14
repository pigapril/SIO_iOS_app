import Foundation

enum AppError: String, Error {
    // General Errors
    case invalidURL = "INVALID_URL"
    case networkError = "NETWORK_ERROR" // Kept original for compatibility
    case timeoutError = "TIMEOUT_ERROR"
    case unknownError = "UNKNOWN_ERROR"
    
    // Auth Errors
    case googleAuthCancelled = "GOOGLE_AUTH_CANCELLED"
    case csrfError = "CSRF_ERROR"

    // API-specific Errors
    case unauthorized = "UNAUTHORIZED"
    case forbidden = "FORBIDDEN"
    case notFound = "NOT_FOUND"
    case validationError = "VALIDATION_ERROR"
    case serverError = "SERVER_ERROR"

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