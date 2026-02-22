import SwiftUI

struct AuthenticationView: View {
    @State private var showSignup = false
    
    var body: some View {
        NavigationView {
            if showSignup {
                SignupView(showSignup: $showSignup)
            } else {
                LoginView(showSignup: $showSignup)
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}
