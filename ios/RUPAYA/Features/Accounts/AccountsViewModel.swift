import SwiftUI
import Combine

class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    
    func loadAccounts() {
        isLoading = true
        
        APIClient.shared.request("/api/v1/accounts", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] (data: [Account]) in
                self?.accounts = data
            })
            .store(in: &cancellables)
        
        APIClient.shared.request("/api/v1/transactions", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Transaction]) in
                self?.transactions = data
            })
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
