import SwiftUI
import Combine

class AddTransactionViewModel: ObservableObject {
    @Published var amount: Double = 0
    @Published var transactionType: String = "expense"
    @Published var transactionDate = Date()
    @Published var selectedAccountId: UUID = UUID()
    @Published var selectedCategoryId: UUID = UUID()
    @Published var notes: String = ""
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var transactionCreated = false
    
    init() {
        loadAccounts()
        loadCategories()
    }
    
    func loadAccounts() {
        APIClient.shared.request("/api/v1/accounts", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Account]) in
                self?.accounts = data
                self?.selectedAccountId = data.first?.accountId ?? UUID()
            })
            .store(in: &cancellables)
    }
    
    func loadCategories() {
        APIClient.shared.request("/api/v1/categories", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Category]) in
                self?.categories = data
                self?.selectedCategoryId = data.first?.categoryId ?? UUID()
            })
            .store(in: &cancellables)
    }
    
    func createTransaction() {
        isLoading = true
        errorMessage = ""
        
        let request = CreateTransactionRequest(
            accountId: selectedAccountId,
            categoryId: selectedCategoryId,
            amount: amount,
            transactionType: transactionType,
            transactionDate: transactionDate,
            merchant: notes.isEmpty ? "Manual Transaction" : notes,
            description: notes
        )
        
        APIClient.shared.request("/api/v1/transactions", method: "POST", body: request)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (_: Transaction) in
                self?.transactionCreated = true
                self?.resetForm()
            })
            .store(in: &cancellables)
    }
    
    private func resetForm() {
        amount = 0
        transactionType = "expense"
        transactionDate = Date()
        notes = ""
    }
    
    private var cancellables = Set<AnyCancellable>()
}

struct CreateTransactionRequest: Codable {
    let accountId: UUID
    let categoryId: UUID
    let amount: Double
    let transactionType: String
    let transactionDate: Date
    let merchant: String
    let description: String
}
