import Foundation

struct SignupRequest: Codable {
    let email: String
    let password: String
    let deviceId: String
    let deviceName: String
}

struct SigninRequest: Codable {
    let email: String
    let password: String
    let deviceId: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct AuthenticationResponse: Codable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let user: User
    let mfaRequired: Bool?
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let currency: String
    let timezone: String
    let theme: String
    let language: String
}

struct Transaction: Codable, Identifiable {
    let id: String
    let amount: Double
    let currency: String
    let type: String
    let category: String
    let description: String
    let date: String
    let status: String
}

struct Account: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let balance: Double
    let currency: String
}

struct Budget: Codable, Identifiable {
    let id: String
    let category: String
    let amount: Double
    let spent: Double
    let period: String
}
