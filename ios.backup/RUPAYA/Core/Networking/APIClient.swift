import Foundation
import Combine
import UIKit

class APIClient: NSObject, URLSessionDelegate {
    static let shared = APIClient()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = [
            "User-Agent": "RUPAYA/1.0 iOS/\(UIDevice.current.systemVersion)",
            "Accept": "application/json",
            "X-API-Version": "v1"
        ]
        
        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: OperationQueue.main
        )
    }()
    
    private var baseURL: String {
        return APIConfig.resolvedBaseURL
    }
    private let keychainManager = KeychainManager.shared
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) -> AnyPublisher<T, Error> {
        let fullURL = "\(baseURL)\(endpoint)"
        
        #if DEBUG
        APIConfig.log("[\(method)] \(fullURL)", type: .network)
        #endif
        
        guard let urlComponents = URLComponents(string: fullURL) else {
            APIConfig.log("Invalid URL: \(fullURL)", type: .error)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authorization header
        if let accessToken = keychainManager.retrieve("access_token") {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request ID
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        
        // Encode body
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONEncoder().encode(body)
                if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                    APIConfig.log("Request body: \(bodyString)", type: .network)
                }
            } catch {
                APIConfig.log("Failed to encode body: \(error)", type: .error)
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                #if DEBUG
                APIConfig.log("Network Error: \(error.localizedDescription) (code: \(error._code))", type: .error)
                #endif
                return error as Error
            }
            .flatMap { data, response -> AnyPublisher<T, Error> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    APIConfig.log("Invalid server response", type: .error)
                    return Fail(error: APIError.badServerResponse(statusCode: 0, message: "Invalid server response")).eraseToAnyPublisher()
                }
                
                #if DEBUG
                APIConfig.log("Response [\(httpResponse.statusCode)]: \(endpoint)", type: .network)
                if let responseString = String(data: data, encoding: .utf8) {
                    APIConfig.log("Response body: \(responseString)", type: .network)
                }
                #endif
                
                // Handle 401 - refresh token and retry
                if httpResponse.statusCode == 401 {
                    return self.refreshTokenAndRetry(endpoint: endpoint, method: method, body: body)
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    // Try to extract error message from response
                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                       let errorMsg = errorResponse["error"] {
                        APIConfig.log("Server error [\(httpResponse.statusCode)]: \(errorMsg)", type: .error)
                        return Fail(error: APIError.badServerResponse(statusCode: httpResponse.statusCode, message: errorMsg)).eraseToAnyPublisher()
                    } else {
                        let errorMsg = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        APIConfig.log("Server error: \(httpResponse.statusCode) - \(errorMsg)", type: .error)
                        return Fail(error: APIError.badServerResponse(statusCode: httpResponse.statusCode, message: errorMsg)).eraseToAnyPublisher()
                    }
                }
                
                return Just(data)
                    .decode(type: T.self, decoder: JSONDecoder())
                    .mapError { decodeError -> Error in
                        APIConfig.log("Decode error: \(decodeError)", type: .error)
                        return APIError.decodingError(decodeError.localizedDescription)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func refreshTokenAndRetry<T: Decodable>(endpoint: String, method: String, body: Encodable?) -> AnyPublisher<T, Error> {
        guard let refreshToken = keychainManager.retrieve("refresh_token") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        
        return request("/api/v1/auth/refresh", method: "POST", body: refreshRequest)
            .handleEvents(
                receiveOutput: { (response: RefreshTokenResponse) in
                    self.keychainManager.save(response.accessToken, forKey: "access_token")
                    self.keychainManager.save(response.refreshToken, forKey: "refresh_token")
                },
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // Clear tokens and redirect to login
                        self.keychainManager.delete("access_token")
                        self.keychainManager.delete("refresh_token")
                    }
                }
            )
            .flatMap { _ in
                self.request(endpoint, method: method, body: body) as AnyPublisher<T, Error>
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - URLSessionDelegate (Certificate Pinning)
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        var secResult = SecTrustResultType.invalid
        let status = SecTrustEvaluateWithError(serverTrust, nil)
        
        if status {
            secResult = .proceed
        }
        
        if secResult == .proceed {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
