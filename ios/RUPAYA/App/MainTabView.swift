import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(1)
            
            AddTransactionView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

// Placeholder views
struct DashboardView: View {
    var body: some View {
        NavigationView {
            Text("Dashboard")
                .navigationTitle("Dashboard")
        }
    }
}

struct TransactionsView: View {
    var body: some View {
        NavigationView {
            Text("Transactions")
                .navigationTitle("Transactions")
        }
    }
}

struct AddTransactionView: View {
    var body: some View {
        NavigationView {
            Text("Add Transaction")
                .navigationTitle("Add Transaction")
        }
    }
}

struct AnalyticsView: View {
    var body: some View {
        NavigationView {
            Text("Analytics")
                .navigationTitle("Analytics")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            Text("Profile")
                .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
