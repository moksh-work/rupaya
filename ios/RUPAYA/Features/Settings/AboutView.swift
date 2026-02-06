import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section("Rupaya") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("001")
                        .foregroundColor(.gray)
                }
            }
            
            Section("Information") {
                Text("Rupaya is a personal finance management app designed to help you track spending, manage budgets, and achieve your financial goals.")
            }
            
            Section("Links") {
                Link("Website", destination: URL(string: "https://rupaya.app") ?? URL(fileURLWithPath: ""))
                Link("Privacy Policy", destination: URL(string: "https://rupaya.app/privacy") ?? URL(fileURLWithPath: ""))
                Link("Terms of Service", destination: URL(string: "https://rupaya.app/terms") ?? URL(fileURLWithPath: ""))
            }
        }
        .navigationTitle("About Rupaya")
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
