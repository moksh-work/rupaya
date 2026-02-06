import SwiftUI
import Combine

class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    
    func loadTransactions() {
        isLoading = true
        
        APIClient.shared.request("/api/v1/transactions", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] (data: [Transaction]) in
                self?.transactions = data
            })
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
