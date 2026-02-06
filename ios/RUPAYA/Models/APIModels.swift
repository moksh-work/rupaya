import Foundation

struct SignupRequest: Codable {
    let email: String
    let password: String
    let deviceId: String
    let deviceName: String
}

struct SigninRequest: Codable {
    let email: String
    let password: String
    let deviceId: String
}

struct PhoneOtpRequest: Codable {
    let phoneNumber: String
    let purpose: String
}

struct SignupPhoneRequest: Codable {
    let email: String
    let phoneNumber: String
    let otp: String
    let deviceId: String
    let deviceName: String
    let name: String?
}

struct SigninPhoneRequest: Codable {
    let phoneNumber: String
    let otp: String
    let deviceId: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct LogoutRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct LogoutResponse: Codable {
    let message: String
}

struct OTPResponse: Codable {
    let message: String
    let otp: String?
}

struct AuthenticationResponse: Codable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let user: User
    let mfaRequired: Bool?
}

struct User: Codable {
    let id: String
    let email: String
    let phoneNumber: String?
    let phoneVerified: Bool?
    let name: String
    let currency: String
    let timezone: String
    let theme: String
    let language: String
}

struct Transaction: Codable, Identifiable {
    let id: String
    let accountId: String
    let categoryId: String
    let amount: Double
    let type: String
    let description: String
    let transactionDate: String
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "transaction_id"
        case accountId = "account_id"
        case categoryId = "category_id"
        case amount
        case type = "transaction_type"
        case description
        case transactionDate = "transaction_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountId = try container.decode(String.self, forKey: .accountId)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        
        // Handle amount as either String or Double
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            amount = Double(amountString) ?? 0.0
        } else {
            amount = try container.decode(Double.self, forKey: .amount)
        }
        
        type = try container.decode(String.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        transactionDate = try container.decode(String.self, forKey: .transactionDate)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
    }
}

struct Account: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let accountType: String
    let currency: String
    let currentBalance: Double
    let isDefault: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "account_id"
        case userId = "user_id"
        case name
        case accountType = "account_type"
        case currency
        case currentBalance = "current_balance"
        case isDefault = "is_default"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        accountType = try container.decode(String.self, forKey: .accountType)
        currency = try container.decode(String.self, forKey: .currency)
        
        // Handle currentBalance as either String or Double
        if let balanceString = try? container.decode(String.self, forKey: .currentBalance) {
            currentBalance = Double(balanceString) ?? 0.0
        } else {
            currentBalance = try container.decode(Double.self, forKey: .currentBalance)
        }
        
        isDefault = try? container.decode(Bool.self, forKey: .isDefault)
    }
}

struct Category: Codable, Identifiable {
    let id: String
    let userId: String?
    let name: String
    let categoryType: String
    let icon: String?
    let color: String?
    let isSystem: Bool?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "category_id"
        case userId = "user_id"
        case name
        case categoryType = "category_type"
        case icon
        case color
        case isSystem = "is_system"
        case createdAt = "created_at"
    }
}

// Removed TransactionsListResponse - API returns array directly

struct DashboardSummary: Codable {
    let totalBalance: Double?
    let income: Double?
    let expenses: Double?
    let savings: Double?
    let savingsRate: Double?
    let spendingByCategory: [CategorySpending]?
    let categoryBreakdown: [CategoryBreakdown]?
    
    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case income
        case expenses
        case savings
        case savingsRate = "savings_rate"
        case spendingByCategory = "spendingByCategory"
        case categoryBreakdown = "category_breakdown"
    }
}

struct CategorySpending: Codable, Identifiable {
    var id: String { category }
    let category: String
    let amount: Double
    
    var categoryName: String? { category }
    var percentage: Double? { nil }
}

struct CategoryBreakdown: Codable, Identifiable {
    var id: String { category }
    let category: String
    let amount: Double
    let percentage: Double
}

struct Budget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID?
    let limit: Double?
    let spent: Double?
    let period: String?
    let createdAt: Date?
    
    var categoryName: String? { nil }
    
    enum CodingKeys: String, CodingKey {
        case id = "budget_id"
        case categoryId = "category_id"
        case limit
        case spent
        case period
        case createdAt = "created_at"
    }
}

struct Goal: Codable, Identifiable {
    let id: UUID
    let goalName: String?
    let targetAmount: Double?
    let currentAmount: Double?
    let targetDate: Date?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "goal_id"
        case goalName = "goal_name"
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case targetDate = "target_date"
        case createdAt = "created_at"
    }
}

// Extended models with better property names
extension Transaction {
    var transactionId: UUID? { UUID(uuidString: id) }
    var merchant: String? { nil }
    var parsedTransactionDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: transactionDate)
    }
}

extension Account {
    var accountId: UUID? { UUID(uuidString: id) }
    var accountName: String? { name }
    var balance: Double { currentBalance }
}

extension Category {
    var categoryId: UUID? { UUID(uuidString: id) }
    var categoryName: String? { name }
}
