import SwiftUI

struct AccountsTabView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @State private var selectedAccountId: UUID?
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: { selectedAccountId = nil }) {
                            Text("All")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedAccountId == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedAccountId == nil ? .white : .black)
                                .cornerRadius(20)
                        }
                        
                        ForEach(viewModel.accounts) { account in
                            Button(action: { selectedAccountId = account.accountId }) {
                                Text(account.accountName ?? "Account")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedAccountId == account.accountId ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedAccountId == account.accountId ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(filteredTransactions, id: \.id) { transaction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.merchant ?? "Transaction")
                                .font(.headline)
                            Text(transaction.parsedTransactionDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Spacer()
                            Text(String(format: "$%.2f", transaction.amount))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .onAppear {
                viewModel.loadAccounts()
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        guard let selectedAccountId = selectedAccountId else {
            return viewModel.transactions
        }
        return viewModel.transactions.filter { $0.accountId == selectedAccountId.uuidString }
    }
}

#Preview {
    AccountsTabView()
        .environmentObject(AppState())
}
