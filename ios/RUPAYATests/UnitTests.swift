/**
 * iOS Unit Tests
 * Tests authentication, API calls, and data models
 */

import XCTest
@testable import RUPAYA

class AuthenticationViewModelTests: XCTestCase {
    var viewModel: LoginViewModel!
    var mockApiClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockAPIClient()
        viewModel = LoginViewModel(apiClient: mockApiClient)
    }

    override func tearDown() {
        viewModel = nil
        mockApiClient = nil
        super.tearDown()
    }

    func testLoginWithValidCredentials() {
        // Given
        let email = "test@example.com"
        let password = "Password123!"
        mockApiClient.loginResponse = .success((token: "mock-token", user: User(id: "123", email: email)))

        // When
        viewModel.login(email: email, password: password)

        // Then
        XCTAssertEqual(viewModel.token, "mock-token")
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.error)
    }

    func testLoginWithInvalidCredentials() {
        // Given
        mockApiClient.loginResponse = .failure(APIError.unauthorized)

        // When
        viewModel.login(email: "test@example.com", password: "wrong")

        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.error)
    }

    func testSignupValidation() {
        // Given
        let validEmail = "test@example.com"
        let validPassword = "SecurePass123!"
        let invalidEmail = "invalid-email"
        let weakPassword = "weak"

        // When & Then
        XCTAssertTrue(viewModel.isValidEmail(validEmail))
        XCTAssertFalse(viewModel.isValidEmail(invalidEmail))
        XCTAssertTrue(viewModel.isValidPassword(validPassword))
        XCTAssertFalse(viewModel.isValidPassword(weakPassword))
    }

    func testPasswordStrengthValidation() {
        // Given & When & Then
        XCTAssertFalse(viewModel.isValidPassword("weak"))
        XCTAssertFalse(viewModel.isValidPassword("NoNumbers!"))
        XCTAssertFalse(viewModel.isValidPassword("nonumbers123"))
        XCTAssertTrue(viewModel.isValidPassword("SecurePass123!"))
    }

    func testSessionExpiration() {
        // Given
        viewModel.token = "valid-token"
        mockApiClient.shouldExpireToken = true

        // When
        viewModel.makeAuthenticatedRequest()

        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.error)
    }
}

class DashboardViewModelTests: XCTestCase {
    var viewModel: EnhancedHomeViewModel!
    var mockApiClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockAPIClient()
        viewModel = EnhancedHomeViewModel(apiClient: mockApiClient)
    }

    func testLoadDashboardData() {
        // Given
        let expectedDashboard = DashboardSummary(
            balance: 5000,
            income: 3000,
            expenses: 1000,
            transactions: []
        )
        mockApiClient.dashboardResponse = .success(expectedDashboard)

        // When
        viewModel.loadDashboard()

        // Then
        XCTAssertEqual(viewModel.balance, 5000)
        XCTAssertEqual(viewModel.income, 3000)
        XCTAssertEqual(viewModel.expenses, 1000)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadDashboardError() {
        // Given
        mockApiClient.dashboardResponse = .failure(APIError.networkError)

        // When
        viewModel.loadDashboard()

        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testBalanceCalculation() {
        // Given
        let transactions: [Transaction] = [
            Transaction(id: "1", amount: 100, type: .income),
            Transaction(id: "2", amount: 50, type: .expense),
            Transaction(id: "3", amount: 200, type: .income)
        ]

        // When
        let balance = viewModel.calculateBalance(transactions: transactions)

        // Then
        XCTAssertEqual(balance, 250) // 100 + 200 - 50
    }
}

class TransactionTests: XCTestCase {
    func testTransactionInitialization() {
        // Given
        let transaction = Transaction(
            id: "1",
            description: "Test",
            amount: 100,
            category: "Food",
            type: .expense,
            date: Date()
        )

        // When & Then
        XCTAssertEqual(transaction.id, "1")
        XCTAssertEqual(transaction.amount, 100)
        XCTAssertEqual(transaction.category, "Food")
        XCTAssertEqual(transaction.type, .expense)
    }

    func testTransactionValidation() {
        // Given
        let invalidAmount = Transaction(id: "1", amount: -100, type: .expense)
        let validTransaction = Transaction(id: "1", amount: 100, type: .expense)

        // When & Then
        XCTAssertFalse(invalidAmount.isValid)
        XCTAssertTrue(validTransaction.isValid)
    }
}

class APIClientTests: XCTestCase {
    var apiClient: APIClient!

    override func setUp() {
        super.setUp()
        apiClient = APIClient()
    }

    func testTokenStorage() {
        // Given
        let token = "test-token-123"

        // When
        apiClient.setAuthToken(token)

        // Then
        XCTAssertEqual(apiClient.getAuthToken(), token)
    }

    func testAuthHeaderConstruction() {
        // Given
        let token = "test-token"
        apiClient.setAuthToken(token)

        // When
        let headers = apiClient.getAuthHeaders()

        // Then
        XCTAssertEqual(headers["Authorization"], "Bearer test-token")
    }
}
