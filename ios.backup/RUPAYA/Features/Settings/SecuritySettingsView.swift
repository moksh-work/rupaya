import SwiftUI

struct SecuritySettingsView: View {
    @State private var faceIdEnabled = true
    @State private var autoLockTime = 5
    
    var body: some View {
        Form {
            Section("Biometric") {
                Toggle("Face ID", isOn: $faceIdEnabled)
            }
            
            Section("Auto-Lock") {
                Picker("Lock after", selection: $autoLockTime) {
                    Text("1 minute").tag(1)
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("Never").tag(0)
                }
            }
        }
        .navigationTitle("Security Settings")
    }
}

#Preview {
    NavigationView {
        SecuritySettingsView()
    }
}
