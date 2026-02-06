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

// MARK: - Enhanced Home View
struct EnhancedHomeView: View {
    @StateObject private var viewModel = EnhancedHomeViewModel()
    @State private var selectedPeriod: Period = .month
    
    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    BalanceHeaderCard(totalBalance: viewModel.totalBalance, isLoading: viewModel.isLoading)
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    
                    QuickActionsBar()
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    if !viewModel.recentTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Activity")
                                    .font(.headline)
                                Spacer()
                                NavigationLink("See all") {
                                    TransactionsFullView()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            
                            ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                                RecentTransactionRow(transaction: transaction)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    
                    VStack(spacing: 12) {
                        if let dashboard = viewModel.dashboard {
                            SummaryCard(title: "Income", amount: dashboard.income, color: .green, icon: "arrow.down.circle.fill")
                            SummaryCard(title: "Expenses", amount: dashboard.expenses, color: .red, icon: "arrow.up.circle.fill")
                            SummaryCard(title: "Net Savings", amount: dashboard.savings, color: .blue, icon: "dollarsign.circle.fill")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    VStack(spacing: 12) {
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(Period.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedPeriod) { newValue in
                            viewModel.loadDashboard(period: newValue.rawValue.lowercased())
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                        } else if let errorMessage = viewModel.errorMessage {
                            ErrorStateView(message: errorMessage) {
                                viewModel.loadDashboard(period: selectedPeriod.rawValue.lowercased())
                            }
                        } else if let dashboard = viewModel.dashboard, !dashboard.spendingByCategory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Spending by Category")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                ForEach(dashboard.spendingByCategory, id: \.category) { spending in
                                    CategoryRow(category: spending.category, amount: spending.amount)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Home")
            .onAppear {
                viewModel.loadDashboard(period: selectedPeriod.rawValue.lowercased())
                viewModel.loadRecentTransactions()
            }
        }
    }
}

struct BalanceHeaderCard: View {
    let totalBalance: Double
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Balance")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            if isLoading {
                ProgressView()
            } else {
                Text("$\(String(format: "%.2f", totalBalance))")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(12)
    }
}

struct QuickActionsBar: View {
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "arrow.up.circle.fill", label: "Expense", color: .red)
            QuickActionButton(icon: "arrow.down.circle.fill", label: "Income", color: .green)
            QuickActionButton(icon: "arrow.left.arrow.right.circle.fill", label: "Transfer", color: .orange)
            Spacer()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RecentTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == "income" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title3)
                .foregroundColor(transaction.type == "income" ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(formatDate(transaction.transactionDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("$\(String(format: "%.2f", transaction.amount))")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding(.vertical, 8)
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

class EnhancedHomeViewModel: ObservableObject {
    @Published var dashboard: DashboardSummary?
    @Published var recentTransactions: [Transaction] = []
    @Published var totalBalance: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadDashboard(period: String = "month") {
        isLoading = true
        errorMessage = nil
        let endpoint = "/api/v1/analytics/dashboard?period=\(period)"
        APIClient.shared.request(endpoint, method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (data: DashboardSummary) in
                self?.dashboard = data
            })
            .store(in: &cancellables)
    }
    
    func loadRecentTransactions() {
        APIClient.shared.request("/api/v1/transactions", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Transaction]) in
                self?.recentTransactions = data.sorted { $0.transactionDate > $1.transactionDate }
                self?.totalBalance = data.reduce(0) { total, transaction in
                    transaction.type == "income" ? total + transaction.amount : total - transaction.amount
                }
            })
            .store(in: &cancellables)
    }
}

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .font(.caption)
            Button("Retry") { onRetry() }
        }
        .padding()
    }
}

// MARK: - Insights View
struct InsightsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedPeriod: Period = .month
    @State private var activeTab: InsightsTab = .analytics
    
    enum Period: String, CaseIterable {
        case week = "Week", month = "Month", year = "Year"
    }
    
    enum InsightsTab: String, CaseIterable {
        case analytics = "Analytics", budgets = "Budgets", goals = "Goals", reports = "Reports"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedPeriod) { newValue in
                    viewModel.loadAnalytics(period: newValue.rawValue.lowercased())
                }
                
                Picker("View", selection: $activeTab) {
                    ForEach(InsightsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewModel.isLoading {
                    ProgressView().frame(maxHeight: .infinity, alignment: .center)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(message: errorMessage) {
                        viewModel.loadAnalytics(period: selectedPeriod.rawValue.lowercased())
                    }.frame(maxHeight: .infinity, alignment: .center)
                } else {
                    TabView(selection: $activeTab) {
                        AnalyticsTabContent(viewModel: viewModel).tag(InsightsTab.analytics)
                        BudgetsTabContent().tag(InsightsTab.budgets)
                        GoalsTabContent().tag(InsightsTab.goals)
                        ReportsTabContent(viewModel: viewModel).tag(InsightsTab.reports)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Insights")
        }
    }
}

struct AnalyticsTabContent: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    var body: some View {
        ScrollView {
            if let analytics = viewModel.analytics {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        AnalyticsRow(label: "Total Income", value: analytics.income, color: .green)
                        AnalyticsRow(label: "Total Expenses", value: analytics.expenses, color: .red)
                        AnalyticsRow(label: "Net Savings", value: analytics.savings, color: .blue)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if !analytics.spendingByCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spending Breakdown")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            ForEach(analytics.spendingByCategory, id: \.category) { spending in
                                CategoryBreakdownRow(category: spending.category, amount: spending.amount, total: analytics.expenses)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct BudgetsTabContent: View {
    let budgets: [BudgetItem] = [
        .init(name: "Groceries", limit: 600, spent: 420, percentage: 70),
        .init(name: "Dining", limit: 300, spent: 195, percentage: 65),
        .init(name: "Transport", limit: 200, spent: 190, percentage: 95),
        .init(name: "Entertainment", limit: 150, spent: 80, percentage: 53)
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(budgets) { budget in
                    BudgetProgressCard(budget: budget)
                }
            }
            .padding()
        }
    }
}

struct BudgetItem: Identifiable {
    let id = UUID()
    let name: String
    let limit: Double
    let spent: Double
    let percentage: Double
}

struct BudgetProgressCard: View {
    let budget: BudgetItem
    var statusColor: Color {
        switch budget.percentage {
        case ..<60: return .green
        case ..<85: return .orange
        default: return .red
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name).font(.headline)
                Spacer()
                Text("$\(String(format: "%.0f", budget.spent)) / $\(String(format: "%.0f", budget.limit))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: budget.spent, total: budget.limit).tint(statusColor)
            HStack {
                Text("\(String(format: "%.0f", budget.percentage))% spent").font(.caption).foregroundColor(statusColor)
                Spacer()
                Text(budget.percentage >= 100 ? "Over budget" : "On track")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(budget.percentage >= 100 ? .red : .green)
            }
        }
        .padding()
        .background(statusColor.opacity(0.08))
        .cornerRadius(10)
    }
}

struct GoalsTabContent: View {
    let goals: [GoalItem] = [
        .init(title: "Emergency Fund", target: 10000, current: 5500),
        .init(title: "Vacation", target: 3000, current: 1200),
        .init(title: "New Laptop", target: 2000, current: 800),
        .init(title: "Car Down Payment", target: 15000, current: 7200)
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(goals) { goal in
                    GoalCard(goal: goal)
                }
            }
            .padding()
        }
    }
}

struct GoalItem: Identifiable {
    let id = UUID()
    let title: String
    let target: Double
    let current: Double
}

struct GoalCard: View {
    let goal: GoalItem
    var percentComplete: Double { min((goal.current / goal.target) * 100, 100) }
    var remainingAmount: Double { max(goal.target - goal.current, 0) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title).font(.headline)
                Spacer()
                Text("\(String(format: "%.0f", percentComplete))%").font(.caption).fontWeight(.semibold).foregroundColor(.blue)
            }
            ProgressView(value: goal.current, total: goal.target).tint(.blue)
            HStack {
                Text("$\(String(format: "%.0f", goal.current)) of $\(String(format: "%.0f", goal.target))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if remainingAmount > 0 {
                    Text("$\(String(format: "%.0f", remainingAmount)) to go").font(.caption).fontWeight(.semibold).foregroundColor(.green)
                } else {
                    Text("Completed!").font(.caption).fontWeight(.semibold).foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(10)
    }
}

struct ReportsTabContent: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    var body: some View {
        ScrollView {
            if let report = viewModel.analytics {
                VStack(alignment: .leading, spacing: 16) {
                    Section(header: Text("Summary").font(.headline).padding(.horizontal)) {
                        VStack(spacing: 12) {
                            AnalyticsRow(label: "Income", value: report.income, color: .green)
                            AnalyticsRow(label: "Expenses", value: report.expenses, color: .red)
                            AnalyticsRow(label: "Savings", value: report.savings, color: .blue)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    if !report.spendingByCategory.isEmpty {
                        Section(header: Text("Top Categories").font(.headline).padding(.horizontal)) {
                            ForEach(report.spendingByCategory.prefix(5), id: \.category) { item in
                                HStack {
                                    Text(item.category)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", item.amount))").fontWeight(.semibold)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

// MARK: - Accounts Tab
struct AccountsTabView: View {
    @StateObject private var accountsVM = AccountsViewModel()
    @StateObject private var transactionsVM = TransactionsViewModel()
    @State private var selectedAccountId: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !accountsVM.accounts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            AccountFilterButton(title: "All Accounts", isSelected: selectedAccountId == nil, action: { selectedAccountId = nil })
                            ForEach(accountsVM.accounts) { account in
                                AccountFilterButton(title: account.name, isSelected: selectedAccountId == account.id, action: { selectedAccountId = account.id })
                            }
                        }
                        .padding()
                    }
                }
                
                if transactionsVM.isLoading {
                    ProgressView().frame(maxHeight: .infinity, alignment: .center)
                } else if let errorMessage = transactionsVM.errorMessage {
                    ErrorStateView(message: errorMessage) { transactionsVM.loadTransactions() }.frame(maxHeight: .infinity, alignment: .center)
                } else if transactionsVM.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
                        Text("No transactions yet").foregroundColor(.secondary)
                    }.frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(transactionsVM.groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(formatDate(date))) {
                                ForEach(transactionsVM.groupedTransactions[date] ?? []) { transaction in
                                    if selectedAccountId == nil || transaction.accountId == selectedAccountId {
                                        TransactionRow(transaction: transaction)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Accounts")
            .onAppear {
                accountsVM.loadAccounts()
                transactionsVM.loadTransactions()
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct AccountFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSecuritySettings = false
    @State private var showingPreferences = false
    
    var body: some View {
        NavigationView {
            List {
                if let user = authViewModel.currentUser {
                    Section {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text(user.name.prefix(1).uppercased())
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name).font(.headline)
                                Text(user.email).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Security & Privacy") {
                    Button { showingSecuritySettings = true } label: {
                        Label("Security Settings", systemImage: "lock.shield.fill")
                    }
                }
                
                Section("Preferences") {
                    Button { showingPreferences = true } label: {
                        Label("Regional & Notifications", systemImage: "globe")
                    }
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("Appearance", systemImage: "paintbrush.fill")
                    }
                }
                
                Section("Data") {
                    NavigationLink(destination: DataManagementView()) {
                        Label("Data Management", systemImage: "icloud.and.arrow.up")
                    }
                }
                
                Section("Support") {
                    Button {
                        if let url = URL(string: "mailto:support@rupaya.in?subject=RUPAYA%20Support") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle.fill")
                    }
                }
                
                Section {
                    Button(role: .destructive) { authViewModel.logout() } label: {
                        HStack {
                            Spacer()
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right").font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSecuritySettings) {
                SecuritySettingsSheet()
            }
            .sheet(isPresented: $showingPreferences) {
                PreferencesSheet()
            }
        }
    }
}

// MARK: - Transactions Full View
struct TransactionsFullView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorStateView(message: errorMessage) { viewModel.loadTransactions() }
            } else if viewModel.transactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
                    Text("No transactions yet").foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(viewModel.groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date))) {
                            ForEach(viewModel.groupedTransactions[date] ?? []) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("All Transactions")
        .onAppear {
            viewModel.loadTransactions()
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Shared Components & Models

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", amount))").font(.title2).fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryRow: View {
    let category: String
    let amount: Double
    var body: some View {
        HStack {
            Text(category).font(.body)
            Spacer()
            Text("$\(String(format: "%.2f", amount))").font(.body).fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description).font(.body)
                Text(formatDate(transaction.transactionDate)).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("$\(String(format: "%.2f", transaction.amount))")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct AnalyticsRow: View {
    let label: String
    let value: Double
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.body)
            Spacer()
            Text("$\(String(format: "%.2f", value))").font(.title3).fontWeight(.bold).foregroundColor(color)
        }
    }
}

struct CategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let total: Double
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return (amount / total) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category).font(.body)
                Spacer()
                Text("$\(String(format: "%.2f", amount))").font(.body).fontWeight(.semibold)
                Text("(\(String(format: "%.1f", percentage))%)").font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal)
    }
}

// MARK: - ViewModels

class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    var groupedTransactions: [String: [Transaction]] {
        Dictionary(grouping: transactions, by: { $0.transactionDate })
    }
    
    func loadTransactions() {
        isLoading = true
        errorMessage = nil
        APIClient.shared.request("/api/v1/transactions", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (data: [Transaction]) in
                self?.transactions = data
            })
            .store(in: &cancellables)
    }
}

class AddTransactionViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var isLoadingLookups = false
    @Published var isCreating = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    func loadLookups() {
        isLoadingLookups = true
        errorMessage = nil
        let accountsPublisher: AnyPublisher<[Account], Error> = APIClient.shared.request("/api/v1/accounts", method: "GET", body: nil as String?)
        let categoriesPublisher: AnyPublisher<[Category], Error> = APIClient.shared.request("/api/v1/categories", method: "GET", body: nil as String?)
        Publishers.Zip(accountsPublisher, categoriesPublisher)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingLookups = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] accounts, categories in
                self?.accounts = accounts
                self?.categories = categories
            })
            .store(in: &cancellables)
    }
    
    func createTransaction(accountId: String, categoryId: String, amount: Double, type: String, description: String, transactionDate: String, completion: @escaping (Bool) -> Void) {
        isCreating = true
        errorMessage = nil
        struct CreateTransactionRequest: Codable {
            let account_id: String
            let category_id: String
            let amount: Double
            let transaction_type: String
            let description: String
            let transaction_date: String
        }
        let body = CreateTransactionRequest(account_id: accountId, category_id: categoryId, amount: amount, transaction_type: type, description: description, transaction_date: transactionDate)
        APIClient.shared.request("/api/v1/transactions", method: "POST", body: body)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isCreating = false
                if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }, receiveValue: { [weak self] (_: Transaction) in
                completion(true)
            })
            .store(in: &cancellables)
    }
}

class AnalyticsViewModel: ObservableObject {
    @Published var analytics: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    func loadAnalytics(period: String = "month") {
        isLoading = true
        errorMessage = nil
        let endpoint = "/api/v1/analytics/dashboard?period=\(period)"
        APIClient.shared.request(endpoint, method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (data: DashboardSummary) in
                self?.analytics = data
            })
            .store(in: &cancellables)
    }
}

class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    func loadAccounts() {
        isLoading = true
        errorMessage = nil
        APIClient.shared.request("/api/v1/accounts", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (data: [Account]) in
                self?.accounts = data
            })
            .store(in: &cancellables)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
