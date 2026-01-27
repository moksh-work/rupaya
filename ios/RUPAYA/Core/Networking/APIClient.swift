import Foundation
import Combine

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
    
    private let baseURL = "https://api.rupaya.in"
    private let keychainManager = KeychainManager.shared
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) -> AnyPublisher<T, Error> {
        guard var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)") else {
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
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        return session.dataTaskPublisher(for: request)
            .mapError { $0 as Error }
            .flatMap { data, response -> AnyPublisher<T, Error> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
                }
                
                // Handle 401 - refresh token and retry
                if httpResponse.statusCode == 401 {
                    return self.refreshTokenAndRetry(endpoint: endpoint, method: method, body: body)
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: T.self, decoder: JSONDecoder())
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func refreshTokenAndRetry<T: Decodable>(endpoint: String, method: String, body: Encodable?) -> AnyPublisher<T, Error> {
        guard let refreshToken = keychainManager.retrieve("refresh_token") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        
        return request("/auth/refresh", method: "POST", body: refreshRequest)
            .handleEvents(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // Clear tokens and redirect to login
                        self.keychainManager.delete("access_token")
                        self.keychainManager.delete("refresh_token")
                    }
                },
                receiveOutput: { (response: AuthenticationResponse) in
                    self.keychainManager.save(response.accessToken, forKey: "access_token")
                    self.keychainManager.save(response.refreshToken, forKey: "refresh_token")
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
