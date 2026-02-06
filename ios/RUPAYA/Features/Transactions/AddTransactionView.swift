import SwiftUI

struct AddTransactionView: View {
    @StateObject private var viewModel = AddTransactionViewModel()
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $viewModel.transactionType) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                        Text("Transfer").tag("transfer")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Amount") {
                    TextField("Amount", value: $viewModel.amount, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                Section("Account") {
                    Picker("From", selection: $viewModel.selectedAccountId) {
                        ForEach(viewModel.accounts) { account in
                            Text(account.accountName ?? "Account").tag(account.accountId)
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            Text(category.categoryName ?? "Category").tag(category.categoryId)
                        }
                    }
                }
                
                Section("Date") {
                    DatePicker("Date", selection: $viewModel.transactionDate, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $viewModel.notes)
                }
                
                Button(action: { viewModel.createTransaction() }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Add Transaction")
                    }
                }
                .disabled(viewModel.isLoading)
            }
            .navigationTitle("Add Transaction")
            .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                Button("OK") { viewModel.errorMessage = "" }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onChange(of: viewModel.transactionCreated) { created in
            if created {
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccess = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AddTransactionView()
    }
}
