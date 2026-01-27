import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Binding var showSignup: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("RUPAYA")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Manifest Your Financial Freedom")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Form
            VStack(spacing: 16) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("your@email.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if showPassword {
                            TextField("••••••••", text: $password)
                        } else {
                            SecureField("••••••••", text: $password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                if let error = authViewModel.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Login Button
            Button(action: {
                authViewModel.loginWithEmail(email: email, password: password)
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text("Sign In")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
            
            // Forgot Password
            Button(action: {}) {
                Text("Forgot Password?")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Biometric Login
            if BiometricManager.shared.isBiometricAvailable {
                Button(action: {
                    authViewModel.loginWithBiometric()
                }) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Use Biometric")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
            
            // Signup Link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                Button(action: { showSignup = true }) {
                    Text("Sign Up")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .font(.caption)
            
            Spacer()
        }
        .padding(20)
    }
}

#Preview {
    LoginView(showSignup: .constant(false))
        .environmentObject(AuthenticationViewModel())
}
