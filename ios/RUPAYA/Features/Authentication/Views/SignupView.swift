import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Binding var showSignup: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var usePhoneOtp = false
    @State private var phoneNumber = ""
    @State private var otp = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Join RUPAYA today")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Form
            VStack(spacing: 16) {
                Picker("Signup Method", selection: $usePhoneOtp) {
                    Text("Email & Password").tag(false)
                    Text("Phone & OTP").tag(true)
                }
                .pickerStyle(.segmented)

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

                if usePhoneOtp {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("+1 555 123 4567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("OTP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Send OTP") {
                                authViewModel.requestOtp(phoneNumber: phoneNumber, purpose: "signup")
                            }
                            .disabled(phoneNumber.isEmpty || authViewModel.isLoading)
                        }
                        TextField("6-digit code", text: $otp)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } else {
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password (min. 12 characters)")
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
                        
                        // Password strength indicator
                        PasswordStrengthView(password: password)
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("••••••••", text: $confirmPassword)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if let error = authViewModel.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if let otpInfo = authViewModel.otpInfo, usePhoneOtp {
                    Text("OTP: \(otpInfo)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Signup Button
            Button(action: {
                if usePhoneOtp {
                    authViewModel.signupWithPhone(email: email, phoneNumber: phoneNumber, otp: otp)
                } else {
                    authViewModel.signupWithEmail(email: email, password: password)
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text("Create Account")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(authViewModel.isLoading || email.isEmpty || (usePhoneOtp ? (phoneNumber.isEmpty || otp.isEmpty) : (password.isEmpty || password != confirmPassword)))
            
            // Login Link
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.secondary)
                Button(action: { showSignup = false }) {
                    Text("Sign In")
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

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: Int {
        var score = 0
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }
    
    private var strengthColor: Color {
        switch strength {
        case 0...2: return .red
        case 3: return .orange
        case 4: return .yellow
        default: return .green
        }
    }
    
    private var strengthText: String {
        switch strength {
        case 0...2: return "Weak"
        case 3: return "Fair"
        case 4: return "Good"
        default: return "Strong"
        }
    }
    
    var body: some View {
        if !password.isEmpty {
            HStack {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index < strength ? strengthColor : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            
            Text(strengthText)
                .font(.caption)
                .foregroundColor(strengthColor)
        }
    }
}

#Preview {
    SignupView(showSignup: .constant(true))
        .environmentObject(AuthenticationViewModel())
}
