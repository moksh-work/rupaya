import SwiftUI
import Combine

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

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod: Period = .month
    
    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .onChange(of: selectedPeriod) { newValue in
                        viewModel.loadDashboard(period: newValue.rawValue.lowercased())
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                viewModel.loadDashboard(period: selectedPeriod.rawValue.lowercased())
                            }
                        }
                        .padding()
                    } else if let dashboard = viewModel.dashboard {
                        // Summary Cards
                        VStack(spacing: 16) {
                            SummaryCard(title: "Income", amount: dashboard.income, color: .green, icon: "arrow.down.circle.fill")
                            SummaryCard(title: "Expenses", amount: dashboard.expenses, color: .red, icon: "arrow.up.circle.fill")
                            SummaryCard(title: "Net Savings", amount: dashboard.savings, color: .blue, icon: "dollarsign.circle.fill")
                            
                            if let rate = Double(dashboard.savingsRate) {
                                HStack {
                                    Text("Savings Rate:")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(String(format: "%.1f", rate))%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(rate >= 0 ? .green : .red)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Spending by Category
                        if !dashboard.spendingByCategory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Spending by Category")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ForEach(dashboard.spendingByCategory, id: \.category) { spending in
                                    CategoryRow(category: spending.category, amount: spending.amount)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.loadDashboard(period: selectedPeriod.rawValue.lowercased())
            }
        }
    }
}

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
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", amount))")
                    .font(.title2)
                    .fontWeight(.bold)
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
            Text(category)
                .font(.body)
            Spacer()
            Text("$\(String(format: "%.2f", amount))")
                .font(.body)
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// Dashboard ViewModel
class DashboardViewModel: ObservableObject {
    @Published var dashboard: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadDashboard(period: String = "month") {
        isLoading = true
        errorMessage = nil
        
        let endpoint = "/api/v1/analytics/dashboard?period=\(period)"
        APIClient.shared.request(endpoint, method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (data: DashboardSummary) in
                    self?.dashboard = data
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Transactions View
struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.loadTransactions()
                        }
                    }
                    .padding()
                } else if viewModel.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No transactions yet")
                            .foregroundColor(.secondary)
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
            .navigationTitle("Transactions")
            .onAppear {
                viewModel.loadTransactions()
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

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.body)
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

// Transactions ViewModel
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
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (data: [Transaction]) in
                    self?.transactions = data
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Add Transaction View
struct AddTransactionView: View {
    @StateObject private var viewModel = AddTransactionViewModel()
    @State private var selectedType: TransactionType = .expense
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedAccountId: String?
    @State private var selectedCategoryId: String?
    @State private var transactionDate = Date()
    @State private var showingSuccess = false
    
    enum TransactionType: String, CaseIterable {
        case income = "income"
        case expense = "expense"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                }
                
                Section("Account") {
                    if viewModel.isLoadingLookups {
                        ProgressView()
                    } else if viewModel.accounts.isEmpty {
                        Text("No accounts available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Account", selection: $selectedAccountId) {
                            Text("Select Account").tag(nil as String?)
                            ForEach(viewModel.accounts) { account in
                                Text(account.name).tag(account.id as String?)
                            }
                        }
                    }
                }
                
                Section("Category") {
                    if viewModel.isLoadingLookups {
                        ProgressView()
                    } else {
                        let categories = viewModel.categories.filter { $0.categoryType == selectedType.rawValue }
                        if categories.isEmpty {
                            Text("No categories available for \(selectedType.rawValue)")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Category", selection: $selectedCategoryId) {
                                Text("Select Category").tag(nil as String?)
                                ForEach(categories) { category in
                                    Text(category.name).tag(category.id as String?)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: createTransaction) {
                        HStack {
                            Spacer()
                            if viewModel.isCreating {
                                ProgressView()
                            } else {
                                Text("Add Transaction")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValid || viewModel.isCreating)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .onAppear {
                viewModel.loadLookups()
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Transaction created successfully!")
            }
        }
    }
    
    var isValid: Bool {
        !amount.isEmpty &&
        !description.isEmpty &&
        selectedAccountId != nil &&
        selectedCategoryId != nil &&
        Double(amount) != nil
    }
    
    func createTransaction() {
        guard let amountValue = Double(amount),
              let accountId = selectedAccountId,
              let categoryId = selectedCategoryId else {
            return
        }
        
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: transactionDate)
        
        viewModel.createTransaction(
            accountId: accountId,
            categoryId: categoryId,
            amount: amountValue,
            type: selectedType.rawValue,
            description: description,
            transactionDate: dateString
        ) { success in
            if success {
                showingSuccess = true
            }
        }
    }
    
    func resetForm() {
        amount = ""
        description = ""
        selectedAccountId = viewModel.accounts.first(where: { $0.isDefault == true })?.id
        selectedCategoryId = nil
        transactionDate = Date()
    }
}

// Add Transaction ViewModel
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
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingLookups = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] accounts, categories in
                    self?.accounts = accounts
                    self?.categories = categories
                }
            )
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
        
        let body = CreateTransactionRequest(
            account_id: accountId,
            category_id: categoryId,
            amount: amount,
            transaction_type: type,
            description: description,
            transaction_date: transactionDate
        )
        
        APIClient.shared.request("/api/v1/transactions", method: "POST", body: body)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isCreating = false
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    }
                },
                receiveValue: { [weak self] (_: Transaction) in
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedPeriod: Period = .month
    
    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
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
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                viewModel.loadAnalytics(period: selectedPeriod.rawValue.lowercased())
                            }
                        }
                        .padding()
                    } else if let analytics = viewModel.analytics {
                        VStack(spacing: 16) {
                            // Summary
                            VStack(spacing: 12) {
                                AnalyticsRow(label: "Total Income", value: analytics.income, color: .green)
                                AnalyticsRow(label: "Total Expenses", value: analytics.expenses, color: .red)
                                AnalyticsRow(label: "Net Savings", value: analytics.savings, color: .blue)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Category Breakdown
                            if !analytics.spendingByCategory.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Spending Breakdown")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    ForEach(analytics.spendingByCategory, id: \.category) { spending in
                                        CategoryBreakdownRow(
                                            category: spending.category,
                                            amount: spending.amount,
                                            total: analytics.expenses
                                        )
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
            .onAppear {
                viewModel.loadAnalytics(period: selectedPeriod.rawValue.lowercased())
            }
        }
    }
}

struct AnalyticsRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Text("$\(String(format: "%.2f", value))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
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
                Text(category)
                    .font(.body)
                Spacer()
                Text("$\(String(format: "%.2f", amount))")
                    .font(.body)
                    .fontWeight(.semibold)
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// Analytics ViewModel
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
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (data: DashboardSummary) in
                    self?.analytics = data
                }
            )
            .store(in: &cancellables)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSecuritySettings = false
    @State private var showingPreferences = false
    @State private var hideAmounts = false
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
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
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(user.currency)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Data & Organization Section
                Section("Organization") {
                    NavigationLink(destination: AccountsManagementView()) {
                        ProfileMenuRow(icon: "banknote.fill", iconColor: .green, title: "Accounts", subtitle: "Manage financial accounts")
                    }
                    
                    NavigationLink(destination: CategoriesManagementView()) {
                        ProfileMenuRow(icon: "folder.fill", iconColor: .orange, title: "Categories", subtitle: "Organize transactions")
                    }
                    
                    NavigationLink(destination: BudgetsGoalsView()) {
                        ProfileMenuRow(icon: "target", iconColor: .red, title: "Budgets & Goals", subtitle: "Track spending goals")
                    }
                }
                
                // Analytics Section
                Section("Analytics & Reports") {
                    NavigationLink(destination: ReportsView()) {
                        ProfileMenuRow(icon: "chart.bar.fill", iconColor: .purple, title: "Reports", subtitle: "Detailed spending analysis")
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        ProfileMenuRow(icon: "icloud.and.arrow.up", iconColor: .teal, title: "Data Management", subtitle: "Backup, restore, export")
                    }
                }
                
                // Security & Privacy Section
                Section("Security & Privacy") {
                    Button {
                        showingSecuritySettings = true
                    } label: {
                        ProfileMenuRow(icon: "lock.shield.fill", iconColor: .green, title: "Security", subtitle: "Face ID, PIN, encryption")
                    }
                    
                    HStack {
                        ProfileMenuRow(icon: "eye.slash.fill", iconColor: .indigo, title: "Hide Amounts", subtitle: "Blur financial data")
                        
                        Spacer()
                        
                        Toggle("", isOn: $hideAmounts)
                            .labelsHidden()
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    Button {
                        showingPreferences = true
                    } label: {
                        ProfileMenuRow(icon: "gearshape.fill", iconColor: .gray, title: "General Settings", subtitle: "Currency, language, notifications")
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        ProfileMenuRow(icon: "paintbrush.fill", iconColor: .pink, title: "Appearance", subtitle: "Theme, colors, display")
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button {
                        if let url = URL(string: "mailto:support@rupaya.in?subject=RUPAYA%20Support") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        ProfileMenuRow(icon: "envelope.fill", iconColor: .blue, title: "Contact Support", subtitle: "Get help with the app")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        ProfileMenuRow(icon: "info.circle.fill", iconColor: .blue, title: "About", subtitle: "Version, privacy, terms")
                    }
                }
                
                // Logout Section
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
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

// MARK: - Profile Menu Row Component
struct ProfileMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Security Settings Sheet
struct SecuritySettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var biometricEnabled = false
    @State private var autoLock = 300 // 5 minutes
    @State private var hideTransactionAmounts = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $biometricEnabled) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)
                            Text("Face ID / Touch ID")
                        }
                    }
                } header: {
                    Text("Biometric Authentication")
                } footer: {
                    Text("Use biometric authentication to unlock the app quickly and securely.")
                }
                
                Section {
                    Picker("Auto-Lock", selection: $autoLock) {
                        Text("Immediately").tag(0)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                        Text("15 minutes").tag(900)
                        Text("Never").tag(-1)
                    }
                } header: {
                    Text("Session Timeout")
                } footer: {
                    Text("The app will lock automatically after this period of inactivity.")
                }
                
                Section {
                    Toggle("Hide Transaction Amounts", isOn: $hideTransactionAmounts)
                    Toggle("Hide Account Balances", isOn: .constant(false))
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Control what information is visible in the app.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Data Encryption")
                                .font(.body)
                            Text("AES-256 encryption enabled")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("Data Security")
                } footer: {
                    Text("All sensitive data is encrypted using AES-256 encryption.")
                }
            }
            .navigationTitle("Security & Privacy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preferences Sheet
struct PreferencesSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCurrency = "USD"
    @State private var selectedLanguage = "English"
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Regional") {
                    Picker("Currency", selection: $selectedCurrency) {
                        Text("USD - US Dollar").tag("USD")
                        Text("EUR - Euro").tag("EUR")
                        Text("GBP - British Pound").tag("GBP")
                        Text("INR - Indian Rupee").tag("INR")
                    }
                    
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("French").tag("French")
                        Text("Hindi").tag("Hindi")
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Transaction Alerts", isOn: .constant(true))
                    Toggle("Budget Warnings", isOn: .constant(true))
                }
                
                Section("Display") {
                    Picker("Date Format", selection: .constant("MM/DD/YYYY")) {
                        Text("MM/DD/YYYY").tag("MM/DD/YYYY")
                        Text("DD/MM/YYYY").tag("DD/MM/YYYY")
                        Text("YYYY-MM-DD").tag("YYYY-MM-DD")
                    }
                }
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2026.01.27")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://rupaya.in/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://rupaya.in/terms")!)
            }
            
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("RUPAYA")
                            .font(.headline)
                        Text("Your Personal Finance Manager")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("© 2026 RUPAYA. All rights reserved.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

// MARK: - Accounts Management
struct AccountsManagementView: View {
    @StateObject private var viewModel = AccountsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Failed to load accounts")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") { viewModel.loadAccounts() }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.accounts) { account in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.headline)
                            Text(account.accountType.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", account.currentBalance))")
                            .font(.headline)
                    }
                }
            }
        }
        .navigationTitle("Accounts")
        .onAppear { viewModel.loadAccounts() }
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
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] (data: [Account]) in
                self?.accounts = data
            }
            .store(in: &cancellables)
    }
}

// MARK: - Categories Management
struct CategoriesManagementView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Failed to load categories")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") { viewModel.loadCategories() }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            } else {
                Section("Income") {
                    ForEach(viewModel.incomeCategories) { category in
                        Text(category.name)
                    }
                }
                Section("Expenses") {
                    ForEach(viewModel.expenseCategories) { category in
                        Text(category.name)
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .onAppear { viewModel.loadCategories() }
    }
}

class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    var incomeCategories: [Category] { categories.filter { $0.categoryType == "income" } }
    var expenseCategories: [Category] { categories.filter { $0.categoryType == "expense" } }
    
    func loadCategories() {
        isLoading = true
        errorMessage = nil
        
        APIClient.shared.request("/api/v1/categories", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] (data: [Category]) in
                self?.categories = data
            }
            .store(in: &cancellables)
    }
}

// MARK: - Budgets & Goals
struct BudgetsGoalsView: View {
    struct Budget: Identifiable {
        let id = UUID()
        let name: String
        let limit: Double
        let spent: Double
    }
    
    private let budgets: [Budget] = [
        .init(name: "Groceries", limit: 600, spent: 420),
        .init(name: "Dining", limit: 300, spent: 195),
        .init(name: "Transport", limit: 200, spent: 190),
        .init(name: "Entertainment", limit: 150, spent: 80)
    ]
    
    var body: some View {
        List {
            Section("Current Budgets") {
                ForEach(budgets) { budget in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(budget.name)
                                .font(.headline)
                            Spacer()
                            Text("$\(String(format: "%.0f", budget.spent)) / $\(String(format: "%.0f", budget.limit))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: budget.spent, total: budget.limit)
                            .tint(progressColor(for: budget))
                    }
                    .padding(.vertical, 4)
                }
            }
            Section("Goals") {
                GoalRow(title: "Emergency Fund", target: 10000, current: 5500)
                GoalRow(title: "Vacation", target: 3000, current: 1200)
                GoalRow(title: "New Laptop", target: 2000, current: 800)
            }
        }
        .navigationTitle("Budgets & Goals")
    }
    
    func progressColor(for budget: Budget) -> Color {
        let ratio = budget.spent / budget.limit
        switch ratio {
        case ..<0.6: return .green
        case ..<0.9: return .orange
        default: return .red
        }
    }
}

struct GoalRow: View {
    let title: String
    let target: Double
    let current: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.0f", current)) / $\(String(format: "%.0f", target))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: current, total: target)
                .tint(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reports
struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedPeriod: AnalyticsView.Period = .month
    
    var body: some View {
        List {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(AnalyticsView.Period.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPeriod) { newValue in
                viewModel.loadReport(period: newValue.rawValue.lowercased())
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Failed to load report")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") { viewModel.loadReport(period: selectedPeriod.rawValue.lowercased()) }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            } else if let report = viewModel.report {
                Section("Summary") {
                    AnalyticsRow(label: "Income", value: report.income, color: .green)
                    AnalyticsRow(label: "Expenses", value: report.expenses, color: .red)
                    AnalyticsRow(label: "Savings", value: report.savings, color: .blue)
                }
                if !report.spendingByCategory.isEmpty {
                    Section("Top Categories") {
                        ForEach(report.spendingByCategory, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text("$\(String(format: "%.2f", item.amount))")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reports")
        .onAppear { viewModel.loadReport(period: selectedPeriod.rawValue.lowercased()) }
    }
}

class ReportsViewModel: ObservableObject {
    @Published var report: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    func loadReport(period: String) {
        isLoading = true
        errorMessage = nil
        let endpoint = "/api/v1/analytics/dashboard?period=\(period)"
        APIClient.shared.request(endpoint, method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] (data: DashboardSummary) in
                self?.report = data
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Management
struct DataManagementView: View {
    @State private var showAlert = false
    
    var body: some View {
        List {
            Section("Backup & Restore") {
                Button {
                    showAlert = true
                } label: {
                    Label("Backup Data", systemImage: "externaldrive.badge.plus")
                }
                Button {
                    showAlert = true
                } label: {
                    Label("Restore Backup", systemImage: "gobackward")
                }
                Button {
                    showAlert = true
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            }
            Section("Privacy") {
                Toggle("Share analytics", isOn: .constant(false))
                Toggle("Include receipts", isOn: .constant(true))
            }
        }
        .navigationTitle("Data Management")
        .alert("Coming soon", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Backup/restore/export will be available in the next release.")
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @State private var useDarkMode = false
    @State private var accentColor: Color = .blue
    @State private var textSize: Double = 1.0
    
    var body: some View {
        Form {
            Section("Theme") {
                Toggle("Dark Mode", isOn: $useDarkMode)
                ColorPicker("Accent Color", selection: $accentColor)
            }
            Section("Typography") {
                HStack {
                    Text("Text Size")
                    Slider(value: $textSize, in: 0.85...1.25, step: 0.05)
                }
                Text("Preview text")
                    .font(.body.weight(.medium))
                    .scaleEffect(textSize)
                    .foregroundStyle(accentColor)
            }
            Section("Layout") {
                Toggle("Compact cards", isOn: .constant(false))
                Toggle("High contrast", isOn: .constant(false))
            }
        }
        .navigationTitle("Appearance")
    }
}
