import Foundation

// MARK: - API Error Types

enum APIError: LocalizedError {
    case badServerResponse(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .badServerResponse(_, let message):
            return message
        case .decodingError(let message):
            return message
        case .networkError(let message):
            return message
        }
    }
}

/// API Configuration for different environments
struct APIConfig {
    
    // MARK: - Environment Configuration
    
    #if DEBUG
    /// Development/Local backend URL
    static let baseURL = "http://localhost:3000"
    static let isDebug = true
    #else
    /// Production backend URL
    static let baseURL = "https://api.rupaya.in"
    static let isDebug = false
    #endif
    
    static let apiVersion = "v1"
    static let timeout: TimeInterval = 30
    
    // MARK: - Resolved URL for different targets
    
    /// Returns the appropriate base URL depending on simulator vs device
    static var resolvedBaseURL: String {
        #if targetEnvironment(simulator)
        // Simulator can access host's localhost directly
        return baseURL
        #else
        // For physical device testing, you need your Mac's local IP
        // Run: ifconfig | grep "inet " | grep -v 127.0.0.1
        // Then update this value with your Mac's IP address
        let macLocalIP = "192.168.1.100" // TODO: Update with your Mac's IP
        return baseURL.replacingOccurrences(of: "localhost", with: macLocalIP)
        #endif
    }
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        static let health = "/health"
        static let signup = "/api/v1/auth/signup"
        static let signin = "/api/v1/auth/signin"
        static let refresh = "/api/v1/auth/refresh"
        static let mfaSetup = "/api/v1/auth/mfa/setup"
        static let mfaVerify = "/api/v1/auth/mfa/verify"
        
        static let accounts = "/api/v1/accounts"
        static let transactions = "/api/v1/transactions"
        static let categories = "/api/v1/categories"
        static let analytics = "/api/v1/analytics"
        static let dashboard = "/api/v1/analytics/dashboard"
        static let budgetProgress = "/api/v1/analytics/budget-progress"
    }
    
    // MARK: - Logging
    
    static func log(_ message: String, type: LogType = .info) {
        #if DEBUG
        let emoji = type.emoji
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("\(emoji) [\(timestamp)] \(message)")
        #endif
    }
    
    enum LogType {
        case info, success, error, warning, network
        
        var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .success: return "✅"
            case .error: return "❌"
            case .warning: return "⚠️"
            case .network: return "🌐"
            }
        }
    }
}
