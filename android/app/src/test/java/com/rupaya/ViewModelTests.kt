/**
 * Android Unit Tests
 * Tests ViewModels, data models, and utilities
 */

package com.rupaya

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.rupaya.features.authentication.presentation.LoginViewModel
import com.rupaya.features.authentication.data.AuthModels
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import kotlinx.coroutines.test.runTest

@RunWith(AndroidJUnit4::class)
class LoginViewModelTests {
    private lateinit var viewModel: LoginViewModel
    private lateinit var mockAuthApi: MockAuthApi

    @Before
    fun setup() {
        mockAuthApi = MockAuthApi()
        viewModel = LoginViewModel(mockAuthApi)
    }

    @Test
    fun testLoginWithValidCredentials() = runTest {
        // Given
        val email = "test@example.com"
        val password = "Password123!"
        mockAuthApi.loginResponse = Result.success(AuthModels.AuthResponse(
            token = "mock-token",
            user = AuthModels.User(id = "123", email = email, firstName = "Test")
        ))

        // When
        viewModel.login(email, password)

        // Then
        assert(viewModel.isAuthenticated.value)
        assert(viewModel.token.value == "mock-token")
    }

    @Test
    fun testLoginWithInvalidCredentials() = runTest {
        // Given
        mockAuthApi.loginResponse = Result.failure(Exception("Invalid credentials"))

        // When
        viewModel.login("test@example.com", "wrong")

        // Then
        assert(!viewModel.isAuthenticated.value)
        assert(viewModel.error.value != null)
    }

    @Test
    fun testEmailValidation() {
        // Given & When & Then
        assert(viewModel.isValidEmail("test@example.com"))
        assert(!viewModel.isValidEmail("invalid-email"))
        assert(!viewModel.isValidEmail(""))
    }

    @Test
    fun testPasswordValidation() {
        // Given & When & Then
        assert(viewModel.isValidPassword("SecurePass123!"))
        assert(!viewModel.isValidPassword("weak"))
        assert(!viewModel.isValidPassword("NoNumbers!"))
        assert(!viewModel.isValidPassword("nonumbers123"))
    }

    @Test
    fun testSignupValidation() {
        // Given
        viewModel.email.value = "test@example.com"
        viewModel.password.value = "SecurePass123!"
        viewModel.confirmPassword.value = "SecurePass123!"
        viewModel.firstName.value = "Test"

        // When
        val isValid = viewModel.isSignupFormValid()

        // Then
        assert(isValid)
    }

    @Test
    fun testPasswordMismatchValidation() {
        // Given
        viewModel.password.value = "SecurePass123!"
        viewModel.confirmPassword.value = "DifferentPass123!"

        // When
        val isValid = viewModel.isSignupFormValid()

        // Then
        assert(!isValid)
    }
}

class HomeViewModelTests {
    private lateinit var viewModel: HomeViewModel
    private lateinit var mockApiService: MockApiService

    @Before
    fun setup() {
        mockApiService = MockApiService()
        viewModel = HomeViewModel(mockApiService)
    }

    @Test
    fun testLoadDashboardData() = runTest {
        // Given
        val expectedBalance = 5000L
        val mockDashboard = AuthModels.DashboardSummary(
            balance = expectedBalance,
            income = 3000L,
            expenses = 1000L,
            transactions = emptyList()
        )
        mockApiService.dashboardResponse = Result.success(mockDashboard)

        // When
        viewModel.loadDashboard()

        // Then
        assert(viewModel.balance.value == expectedBalance)
        assert(viewModel.income.value == 3000L)
        assert(viewModel.expenses.value == 1000L)
        assert(!viewModel.isLoading.value)
    }

    @Test
    fun testLoadDashboardError() = runTest {
        // Given
        mockApiService.dashboardResponse = Result.failure(Exception("Network error"))

        // When
        viewModel.loadDashboard()

        // Then
        assert(viewModel.error.value != null)
        assert(!viewModel.isLoading.value)
    }

    @Test
    fun testBalanceCalculation() {
        // Given
        val transactions = listOf(
            AuthModels.Transaction(id = "1", amount = 100, type = "income"),
            AuthModels.Transaction(id = "2", amount = 50, type = "expense"),
            AuthModels.Transaction(id = "3", amount = 200, type = "income")
        )

        // When
        val balance = viewModel.calculateBalance(transactions)

        // Then
        assert(balance == 250L) // 100 + 200 - 50
    }

    @Test
    fun testRefreshDashboard() = runTest {
        // Given
        val initialBalance = 5000L
        val updatedBalance = 5500L

        mockApiService.dashboardResponse = Result.success(AuthModels.DashboardSummary(
            balance = initialBalance,
            income = 3000L,
            expenses = 1000L,
            transactions = emptyList()
        ))
        viewModel.loadDashboard()

        // When
        mockApiService.dashboardResponse = Result.success(AuthModels.DashboardSummary(
            balance = updatedBalance,
            income = 3500L,
            expenses = 1000L,
            transactions = emptyList()
        ))
        viewModel.refresh()

        // Then
        assert(viewModel.balance.value == updatedBalance)
    }
}

class TransactionTests {
    @Test
    fun testTransactionInitialization() {
        // Given
        val transaction = AuthModels.Transaction(
            id = "1",
            description = "Test",
            amount = 100,
            category = "Food",
            type = "expense"
        )

        // When & Then
        assert(transaction.id == "1")
        assert(transaction.amount == 100L)
        assert(transaction.category == "Food")
        assert(transaction.type == "expense")
    }

    @Test
    fun testTransactionValidation() {
        // Given & When & Then
        assert(!isValidTransaction(amount = -100))
        assert(isValidTransaction(amount = 100))
        assert(!isValidTransaction(category = ""))
    }

    private fun isValidTransaction(
        amount: Long = 100,
        category: String = "Food"
    ): Boolean {
        return amount > 0 && category.isNotEmpty()
    }
}

class CurrencyFormattingTests {
    @Test
    fun testCurrencyFormatting() {
        // Given
        val amount = 1234.56

        // When
        val formatted = formatCurrency(amount)

        // Then
        assert(formatted == "$1,234.56")
    }

    @Test
    fun testNegativeAmountFormatting() {
        // Given
        val amount = -500.00

        // When
        val formatted = formatCurrency(amount)

        // Then
        assert(formatted == "-$500.00")
    }

    private fun formatCurrency(amount: Double): String {
        return if (amount >= 0) {
            "$${String.format("%.2f", amount)}"
        } else {
            "-$${String.format("%.2f", kotlin.math.abs(amount))}"
        }
    }
}

// Mock Classes
class MockAuthApi {
    var loginResponse: Result<AuthModels.AuthResponse> = Result.failure(Exception("Not mocked"))

    suspend fun login(email: String, password: String): Result<AuthModels.AuthResponse> {
        return loginResponse
    }
}

class MockApiService {
    var dashboardResponse: Result<AuthModels.DashboardSummary> = Result.failure(Exception("Not mocked"))

    suspend fun getDashboard(): Result<AuthModels.DashboardSummary> {
        return dashboardResponse
    }
}
