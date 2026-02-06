import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSecuritySettings = false
    @State private var showingPreferences = false
    @State private var showingAppearance = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text("User")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("user@example.com")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text("USD")
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Security & Privacy") {
                    Toggle("Face ID", isOn: .constant(true))
                    NavigationLink(destination: SecuritySettingsView()) {
                        Text("More Security Options")
                    }
                }
                
                Section("App") {
                    NavigationLink(destination: PreferencesView()) {
                        Text("Preferences")
                    }
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Text("Appearance")
                    }
                    NavigationLink(destination: DataManagementView()) {
                        Text("Data & Privacy")
                    }
                }
                
                Section("Support") {
                    NavigationLink(destination: AboutView()) {
                        Text("About Rupaya")
                    }
                    Link("Contact Support", destination: URL(string: "mailto:support@rupaya.app") ?? URL(string: "https://rupaya.app")!)
                }
                
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                    } label: {
                        Text("Logout")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AuthenticationViewModel())
}
