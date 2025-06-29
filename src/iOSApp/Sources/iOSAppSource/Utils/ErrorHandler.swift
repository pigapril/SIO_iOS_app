import Foundation

enum AppError: Error {
    // General Errors
    case invalidURL // No raw value here, will use `id` property
    case networkError
    case timeoutError
    case unknownError
    
    // New case for backend errors with specific codes and messages
    case backendError(code: String, message: String)

    // Auth Errors
    case googleAuthCancelled
    case csrfError

    // API-specific Errors
    case unauthorized
    case forbidden
    case notFound
    case validationError
    case serverError

    // Computed property to provide a string identifier for each error case
    var id: String {
        switch self {
        case .invalidURL: return "INVALID_URL"
        case .networkError: return "NETWORK_ERROR"
        case .timeoutError: return "TIMEOUT_ERROR"
        case .unknownError: return "UNKNOWN_ERROR"
        case .backendError(let code, _): return code // Use the code from backendError
        case .googleAuthCancelled: return "GOOGLE_AUTH_CANCELLED"
        case .csrfError: return "CSRF_ERROR"
        case .unauthorized: return "UNAUTHORIZED"
        case .forbidden: return "FORBIDDEN"
        case .notFound: return "NOT_FOUND"
        case .validationError: return "VALIDATION_ERROR"
        case .serverError: return "SERVER_ERROR"
        }
    }

    // Custom initializer to determine error from various sources
    init(error: Error) {
                if let decodingError = error as? DecodingError {
            print("================ DECODING ERROR DETECTED ================")
            print("Raw Error: \(decodingError)")
            
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type Mismatch: '\(type)' was expected, but a different type was found.")
                print("Debug Description: \(context.debugDescription)")
                print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                
            case .valueNotFound(let value, let context):
                print("Value Not Found: Expected value of type '\(value)' but found null instead.")
                print("Debug Description: \(context.debugDescription)")
                print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                
            case .keyNotFound(let key, let context):
                print("Key Not Found: The key '\(key.stringValue)' was not found.")
                print("Debug Description: \(context.debugDescription)")
                print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                
            case .dataCorrupted(let context):
                print("Data Corrupted: The data appears to be malformed.")
                print("Debug Description: \(context.debugDescription)")
                print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                
            @unknown default:
                print("An unknown decoding error occurred.")
            }
            print("=======================================================")
        }

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
        default:
            // If the error is already an AppError, preserve it
            if let appError = error as? AppError {
                self = appError
            } else {
                self = .unknownError
            }
        }
    }
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error.invalidURL", bundle: .module, comment: "Invalid URL error")
        case .networkError:
            return NSLocalizedString("error.network", bundle: .module, comment: "Network connection error")
        case .timeoutError:
            return NSLocalizedString("error.timeout", bundle: .module, comment: "Request timed out")
        case .unknownError:
            return NSLocalizedString("error.unknown", bundle: .module, comment: "An unknown error occurred")
        case .backendError(_, let message): // Use the message from backendError
            return message
        case .googleAuthCancelled:
            return NSLocalizedString("error.googleAuthCancelled", bundle: .module, comment: "Google authentication was cancelled")
        case .csrfError:
            return NSLocalizedString("error.csrf", bundle: .module, comment: "CSRF token error")
        case .unauthorized:
            return NSLocalizedString("error.unauthorized", bundle: .module, comment: "Unauthorized access")
        case .forbidden:
            return NSLocalizedString("error.forbidden", bundle: .module, comment: "Access forbidden")
        case .notFound:
            return NSLocalizedString("error.notFound", bundle: .module, comment: "Resource not found")
        case .validationError:
            return NSLocalizedString("error.validation", bundle: .module, comment: "Validation failed")
        case .serverError:
            return NSLocalizedString("error.server", bundle: .module, comment: "Server error")
        }
    }
}

class ErrorHandler {
    static func handle(error: Error, component: String = "Unknown") {
        let appError = AppError(error: error)
        
        Analytics.logError(
            status: (error as NSError).code,
            // Use the new 'id' property instead of 'rawValue'
            errorCode: appError.id, 
            message: "[\(appError.id)] \(appError.errorDescription ?? error.localizedDescription)", // Use errorDescription
            component: component,
            path: "" // Should be determined by the view
        )

        // Here you would typically show an alert to the user
        // For now, we'll just print to the console
        print("Error handled: \(appError.id), component: \(component)")
    }
} 