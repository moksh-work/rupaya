import SwiftUI

struct EnhancedHomeView: View {
    @StateObject private var viewModel = EnhancedHomeViewModel()
    @State private var selectedPeriod = "Month"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    BalanceHeaderCard(balance: viewModel.totalBalance)
                    
                    QuickActionsBar()
                    
                    HStack {
                        Text("Summary")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        SummaryCard(title: "Income", amount: 5000, color: .green)
                        SummaryCard(title: "Expenses", amount: 2000, color: .red)
                        SummaryCard(title: "Net Savings", amount: 3000, color: .blue)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Recent Transactions")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: TransactionsFullView()) {
                            Text("See all")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                            RecentTransactionRow(transaction: transaction)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

struct BalanceHeaderCard: View {
    let balance: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Balance")
                .font(.caption)
                .foregroundColor(.gray)
            Text(String(format: "$%.2f", balance))
                .font(.system(size: 32, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickActionsBar: View {
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: AddTransactionView()) {
                VStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                    Text("Expense")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            NavigationLink(destination: AddTransactionView()) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Income")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            NavigationLink(destination: AddTransactionView()) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.title2)
                    Text("Transfer")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .foregroundColor(.primary)
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "$%.2f", amount))
                    .font(.headline)
            }
            Spacer()
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(color, lineWidth: 2))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct RecentTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? "Transaction")
                    .font(.headline)
                Text(transaction.parsedTransactionDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(String(format: "$%.2f", transaction.amount))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    EnhancedHomeView()
        .environmentObject(AppState())
}
