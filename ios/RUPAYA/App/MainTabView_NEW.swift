import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Tab 0: HOME
            EnhancedHomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            // Tab 1: INSIGHTS
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(1)
            
            // Tab 2: ADD
            AddTransactionView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(2)
            
            // Tab 3: ACCOUNTS
            AccountsTabView()
                .tabItem { Label("Accounts", systemImage: "creditcard.fill") }
                .tag(3)
            
            // Tab 4: SETTINGS
            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
