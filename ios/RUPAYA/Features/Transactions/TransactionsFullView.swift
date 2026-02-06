import SwiftUI

struct TransactionsFullView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.transactions) { transaction in
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
        .navigationTitle("All Transactions")
        .onAppear {
            viewModel.loadTransactions()
        }
    }
}

#Preview {
    NavigationView {
        TransactionsFullView()
    }
}
