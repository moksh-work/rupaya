import SwiftUI
import Combine

class EnhancedHomeViewModel: ObservableObject {
    @Published var totalBalance: Double = 0
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    
    func loadData() {
        isLoading = true
        
        // Fetch total balance
        APIClient.shared.request("/api/v1/analytics/dashboard", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] (data: DashboardSummary) in
                self?.totalBalance = data.totalBalance ?? 0
            })
            .store(in: &cancellables)
        
        // Fetch recent transactions
        APIClient.shared.request("/api/v1/transactions", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Transaction]) in
                self?.recentTransactions = data
            })
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
