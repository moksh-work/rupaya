import SwiftUI
import Combine

class AnalyticsViewModel: ObservableObject {
    @Published var categoryBreakdown: [CategoryBreakdown] = []
    @Published var budgets: [Budget] = []
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    
    func loadData() {
        isLoading = true
        
        // Fetch analytics
        APIClient.shared.request("/api/v1/analytics/dashboard", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] (data: DashboardSummary) in
                self?.categoryBreakdown = data.categoryBreakdown ?? []
            })
            .store(in: &cancellables)
        
        // Fetch budgets
        APIClient.shared.request("/api/v1/budgets", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Budget]) in
                self?.budgets = data
            })
            .store(in: &cancellables)
        
        // Fetch goals
        APIClient.shared.request("/api/v1/goals", method: "GET", body: nil as String?)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (data: [Goal]) in
                self?.goals = data
            })
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
