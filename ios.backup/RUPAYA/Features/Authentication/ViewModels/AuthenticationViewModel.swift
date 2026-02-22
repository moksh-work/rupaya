import Combine
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isLoading = false
    @Published var otpInfo: String?
    
    private let apiClient = APIClient.shared
    private let keychainManager = KeychainManager.shared
    private let biometricManager = BiometricManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if keychainManager.retrieve("access_token") != nil {
            isAuthenticated = true
            if biometricManager.isBiometricAvailable {
                biometricManager.authenticate { [weak self] result in
                    switch result {
                    case .success:
                        break
                    case .failure:
                        self?.logout()
                    }
                }
            }
        }
    }
    
    func signupWithEmail(email: String, password: String) {
        isLoading = true
        
        guard validatePasswordStrength(password) else {
            authError = "Password is too weak"
            isLoading = false
            return
        }
        
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let signupRequest = SignupRequest(
            email: email,
            password: password,
            deviceId: deviceID,
            deviceName: UIDevice.current.name
        )
        
        apiClient.request("/api/v1/auth/signup", method: "POST", body: signupRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] (response: AuthenticationResponse) in
                self?.handleAuthenticationResponse(response)
            }
            .store(in: &cancellables)
    }

    func signupWithPhone(email: String, phoneNumber: String, otp: String, name: String? = nil) {
        isLoading = true
        authError = nil
        otpInfo = nil
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let request = SignupPhoneRequest(
            email: email,
            phoneNumber: phoneNumber,
            otp: otp,
            deviceId: deviceID,
            deviceName: UIDevice.current.name,
            name: name
        )
        apiClient.request("/api/v1/auth/signup-phone", method: "POST", body: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] (response: AuthenticationResponse) in
                self?.handleAuthenticationResponse(response)
            }
            .store(in: &cancellables)
    }
    
    func loginWithEmail(email: String, password: String) {
        isLoading = true
        
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let signinRequest = SigninRequest(
            email: email,
            password: password,
            deviceId: deviceID
        )
        
        apiClient.request("/api/v1/auth/signin", method: "POST", body: signinRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] (response: AuthenticationResponse) in
                if response.mfaRequired == true {
                    self?.authError = "MFA required"
                } else {
                    self?.handleAuthenticationResponse(response)
                }
            }
            .store(in: &cancellables)
    }

    func signinWithPhone(phoneNumber: String, otp: String) {
        isLoading = true
        authError = nil
        otpInfo = nil
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let request = SigninPhoneRequest(phoneNumber: phoneNumber, otp: otp, deviceId: deviceID)
        apiClient.request("/api/v1/auth/signin-phone", method: "POST", body: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] (response: AuthenticationResponse) in
                self?.handleAuthenticationResponse(response)
            }
            .store(in: &cancellables)
    }

    func requestOtp(phoneNumber: String, purpose: String) {
        isLoading = true
        authError = nil
        otpInfo = nil
        let request = PhoneOtpRequest(phoneNumber: phoneNumber, purpose: purpose)
        apiClient.request("/api/v1/auth/otp/request", method: "POST", body: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            } receiveValue: { [weak self] (response: OTPResponse) in
                self?.otpInfo = response.otp ?? "OTP sent"
            }
            .store(in: &cancellables)
    }
    
    func loginWithBiometric() {
        biometricManager.authenticate { [weak self] result in
            switch result {
            case .success:
                if let refreshToken = self?.keychainManager.retrieve("refresh_token") {
                    self?.refreshAccessToken(refreshToken)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.authError = error.localizedDescription
                }
            }
        }
    }
    
    func logout() {
        if let refreshToken = keychainManager.retrieve("refresh_token") {
            let request = LogoutRequest(refreshToken: refreshToken)
            apiClient.request("/api/v1/auth/logout", method: "POST", body: request)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.keychainManager.delete("access_token")
                    self?.keychainManager.delete("refresh_token")
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                } receiveValue: { (_: LogoutResponse) in }
                .store(in: &cancellables)
            return
        }

        keychainManager.delete("access_token")
        keychainManager.delete("refresh_token")
        isAuthenticated = false
        currentUser = nil
    }
    
    private func handleAuthenticationResponse(_ response: AuthenticationResponse) {
        keychainManager.save(response.accessToken, forKey: "access_token")
        keychainManager.save(response.refreshToken, forKey: "refresh_token")
        currentUser = response.user
        isAuthenticated = true
    }
    
    private func refreshAccessToken(_ refreshToken: String) {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        apiClient.request("/api/v1/auth/refresh", method: "POST", body: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.logout()
                }
            } receiveValue: { [weak self] (response: RefreshTokenResponse) in
                self?.keychainManager.save(response.accessToken, forKey: "access_token")
                self?.keychainManager.save(response.refreshToken, forKey: "refresh_token")
            }
            .store(in: &cancellables)
    }
    
    private func validatePasswordStrength(_ password: String) -> Bool {
        let patterns = [
            "^.{12,}$",     // Minimum 12 characters
            "[A-Z]",        // Uppercase
            "[a-z]",        // Lowercase
            "[0-9]",        // Digit
            "[^A-Za-z0-9]"  // Special character
        ]
        
        return patterns.allSatisfy { pattern in
            password.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
