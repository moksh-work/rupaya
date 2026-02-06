import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Tab", selection: $selectedTab) {
                    Text("Analytics").tag(0)
                    Text("Budgets").tag(1)
                    Text("Goals").tag(2)
                    Text("Reports").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Analytics Tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spending by Category")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.categoryBreakdown) { item in
                                    AnalyticsRow(category: item.category, amount: item.amount, percentage: item.percentage)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .tag(0)
                    
                    // Budgets Tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monthly Budgets")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.budgets) { budget in
                                    BudgetProgressCard(budget: budget)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .tag(1)
                    
                    // Goals Tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Financial Goals")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.goals) { goal in
                                    GoalCard(goal: goal)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .tag(2)
                    
                    // Reports Tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Period Reports")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.categoryBreakdown) { item in
                                    AnalyticsRow(category: item.category, amount: item.amount, percentage: item.percentage)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Insights")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

struct AnalyticsRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category)
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", amount))
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100))
                }
                .frame(height: 8)
            }
            .frame(height: 8)
            
            HStack {
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct BudgetProgressCard: View {
    let budget: Budget
    
    var color: Color {
        let spent = (budget.spent ?? 0) / (budget.limit ?? 1)
        if spent > 1 {
            return .red
        } else if spent > 0.8 {
            return .orange
        }
        return .green
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(budget.categoryName ?? "Budget")
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f / $%.2f", budget.spent ?? 0, budget.limit ?? 0))
                    .font(.caption)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min((budget.spent ?? 0) / (budget.limit ?? 1), 1)))
                }
                .frame(height: 10)
            }
            .frame(height: 10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct GoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(goal.goalName ?? "Goal")
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f / $%.2f", goal.currentAmount ?? 0, goal.targetAmount ?? 0))
                    .font(.caption)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(min((goal.currentAmount ?? 0) / (goal.targetAmount ?? 1), 1)))
                }
                .frame(height: 10)
            }
            .frame(height: 10)
            
            HStack {
                Text("Target: " + (goal.targetDate?.formatted(date: .abbreviated, time: .omitted) ?? ""))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    InsightsView()
        .environmentObject(AppState())
}
