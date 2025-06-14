import Foundation

struct Analytics {
    static func error(
        status: Int,
        errorCode: String,
        message: String,
        component: String,
        path: String,
        timestamp: String = Date().ISO8601Format()
    ) {
        let errorData: [String: Any] = [
            "status": status,
            "errorCode": errorCode,
            "message": message,
            "component": component,
            "path": path,
            "timestamp": timestamp
        ]
        
        // In a real app, you would send this to your analytics service
        // For now, we'll just print to the console
        print("Analytics Error: \(errorData)")
    }
    
    // Alias for logError to match ErrorHandler
    static func logError(status: Int, errorCode: String, message: String, component: String, path: String) {
        error(status: status, errorCode: errorCode, message: message, component: component, path: path)
    }
} 