import LocalAuthentication

class BiometricManager {
    static let shared = BiometricManager()
    
    private init() {}
    
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }
    
    func authenticate(completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            completion(.failure(error ?? NSError()))
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to access RUPAYA"
        ) { success, authError in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(authError ?? NSError()))
            }
        }
    }
    
    func getBiometricType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
}
