import SwiftUI

struct PreferencesView: View {
    @State private var selectedCurrency = "USD"
    @State private var selectedLanguage = "English"
    @State private var notificationsEnabled = true
    
    var body: some View {
        Form {
            Section("Currency") {
                Picker("Currency", selection: $selectedCurrency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                }
            }
            
            Section("Language") {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                }
            }
            
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
        }
        .navigationTitle("Preferences")
    }
}

#Preview {
    NavigationView {
        PreferencesView()
    }
}
