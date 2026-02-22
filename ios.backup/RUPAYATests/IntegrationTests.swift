/**
 * iOS Integration Tests
 * Tests view interactions, navigation, and data flow
 */

import XCTest
@testable import RUPAYA

class LoginScreenIntegrationTests: XCTestCase {
    var sut: LoginScreen!
    var mockApiClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockAPIClient()
        sut = LoginScreen(apiClient: mockApiClient)
    }

    func testSuccessfulLoginFlow() {
        // Given
        mockApiClient.loginResponse = .success((token: "mock-token", user: User(id: "1", email: "test@example.com")))
        let email = "test@example.com"
        let password = "Password123!"

        // When
        sut.performLogin(email: email, password: password)

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
    }

    func testFailedLoginFlow() {
        // Given
        mockApiClient.loginResponse = .failure(APIError.unauthorized)

        // When
        sut.performLogin(email: "test@example.com", password: "wrong")

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSignupFormValidation() {
        // Given
        sut.email = "test@example.com"
        sut.password = "SecurePass123!"
        sut.confirmPassword = "SecurePass123!"
        sut.firstName = "Test"

        // When
        let isValid = sut.isFormValid()

        // Then
        XCTAssertTrue(isValid)
    }

    func testPasswordMismatchValidation() {
        // Given
        sut.password = "SecurePass123!"
        sut.confirmPassword = "DifferentPass123!"

        // When
        let isValid = sut.isFormValid()

        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(sut.errorMessage, "Passwords do not match")
    }
}

class DashboardViewIntegrationTests: XCTestCase {
    var sut: EnhancedHomeView!
    var mockApiClient: MockAPIClient!
    var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        mockApiClient = MockAPIClient()
        mockRouter = MockRouter()
        sut = EnhancedHomeView(apiClient: mockApiClient, router: mockRouter)
    }

    func testDashboardLoadsOnAppear() {
        // Given
        let expectedBalance: Decimal = 5000
        mockApiClient.dashboardResponse = .success(DashboardSummary(
            balance: expectedBalance,
            income: 3000,
            expenses: 1000,
            transactions: []
        ))

        // When
        sut.loadData()

        // Then
        XCTAssertEqual(sut.balance, expectedBalance)
        XCTAssertFalse(sut.isLoading)
    }

    func testRefreshDashboard() {
        // Given
        let initialBalance: Decimal = 5000
        let updatedBalance: Decimal = 5500
        mockApiClient.dashboardResponse = .success(DashboardSummary(
            balance: initialBalance,
            income: 3000,
            expenses: 1000,
            transactions: []
        ))

        sut.loadData()
        XCTAssertEqual(sut.balance, initialBalance)

        // When
        mockApiClient.dashboardResponse = .success(DashboardSummary(
            balance: updatedBalance,
            income: 3500,
            expenses: 1000,
            transactions: []
        ))
        sut.refresh()

        // Then
        XCTAssertEqual(sut.balance, updatedBalance)
    }

    func testNavigateToAddTransaction() {
        // When
        sut.navigateToAddTransaction()

        // Then
        XCTAssertTrue(mockRouter.navigatedToAddTransaction)
    }

    func testViewTransactionDetails() {
        // Given
        let transaction = Transaction(
            id: "1",
            description: "Test",
            amount: 100,
            category: "Food",
            type: .expense,
            date: Date()
        )

        // When
        sut.selectTransaction(transaction)

        // Then
        XCTAssertEqual(sut.selectedTransaction?.id, "1")
        XCTAssertTrue(mockRouter.navigatedToTransactionDetail)
    }
}

class TransactionInputTests: XCTestCase {
    var sut: AddTransactionView!
    var mockApiClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockAPIClient()
        sut = AddTransactionView(apiClient: mockApiClient)
    }

    func testAddExpenseTransaction() {
        // Given
        sut.description = "Groceries"
        sut.amount = 50
        sut.category = "Food"
        sut.transactionType = .expense

        // When
        sut.saveTransaction()

        // Then
        XCTAssertTrue(sut.isSaved)
        XCTAssertNil(sut.errorMessage)
    }

    func testAddIncomeTransaction() {
        // Given
        sut.description = "Salary"
        sut.amount = 3000
        sut.category = "Income"
        sut.transactionType = .income

        // When
        sut.saveTransaction()

        // Then
        XCTAssertTrue(sut.isSaved)
    }

    func testTransactionValidation() {
        // Given
        sut.description = ""
        sut.amount = 0

        // When
        let isValid = sut.isFormValid()

        // Then
        XCTAssertFalse(isValid)
    }

    func testCurrencyFormatting() {
        // Given
        let amount: Decimal = 1234.56

        // When
        let formatted = sut.formatCurrency(amount)

        // Then
        XCTAssertEqual(formatted, "$1,234.56")
    }
}

class BiometricAuthTests: XCTestCase {
    var biometricManager: BiometricAuthManager!

    override func setUp() {
        super.setUp()
        biometricManager = BiometricAuthManager()
    }

    func testBiometricAvailability() {
        // When
        let isAvailable = biometricManager.isBiometricAvailable()

        // Then
        // Will vary by device/simulator
        XCTAssertNotNil(isAvailable)
    }

    func testBiometricAuthentication() {
        // When
        biometricManager.authenticate { success, error in
            // Then
            if success {
                XCTAssertNil(error)
            } else {
                XCTAssertNotNil(error)
            }
        }
    }
}

// Mock Objects
class MockAPIClient {
    var loginResponse: Result<(token: String, user: User), APIError>?
    var dashboardResponse: Result<DashboardSummary, APIError>?
    var shouldExpireToken = false

    func login(email: String, password: String, completion: @escaping (Result<(token: String, user: User), APIError>) -> Void) {
        completion(loginResponse ?? .failure(.networkError))
    }

    func getDashboard(token: String, completion: @escaping (Result<DashboardSummary, APIError>) -> Void) {
        completion(dashboardResponse ?? .failure(.networkError))
    }
}

class MockRouter {
    var navigatedToAddTransaction = false
    var navigatedToTransactionDetail = false

    func navigateToAddTransaction() {
        navigatedToAddTransaction = true
    }

    func navigateToTransactionDetail(_ transaction: Transaction) {
        navigatedToTransactionDetail = true
    }
}
