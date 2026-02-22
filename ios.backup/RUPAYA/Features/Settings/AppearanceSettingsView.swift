import SwiftUI

struct AppearanceSettingsView: View {
    @State private var selectedTheme = "System"
    @State private var textSize = 1.0
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $selectedTheme) {
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                    Text("System").tag("System")
                }
            }
            
            Section("Text Size") {
                Slider(value: $textSize, in: 0.8...1.2, step: 0.1)
                    .padding(.vertical, 4)
                Text("Preview Text")
                    .font(.system(size: 16 * textSize))
            }
        }
        .navigationTitle("Appearance")
    }
}

#Preview {
    NavigationView {
        AppearanceSettingsView()
    }
}
