import SwiftUI

struct DataManagementView: View {
    @State private var showingExportAlert = false
    
    var body: some View {
        Form {
            Section("Backup") {
                Button("Create Backup") {
                    // TODO: Implement backup
                }
                Button("Restore from Backup") {
                    // TODO: Implement restore
                }
            }
            
            Section("Export") {
                Button("Export Data as CSV") {
                    showingExportAlert = true
                }
            }
        }
        .navigationTitle("Data & Privacy")
        .alert("Export Data", isPresented: $showingExportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Export") {
                // TODO: Implement export
            }
        } message: {
            Text("Export all your transaction data as CSV?")
        }
    }
}

#Preview {
    NavigationView {
        DataManagementView()
    }
}
