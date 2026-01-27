import SwiftUI

@main
struct RUPAYAApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(appState)
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showSettings = false
}
