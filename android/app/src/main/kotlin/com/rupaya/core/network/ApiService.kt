package com.rupaya.core.network

import com.rupaya.features.authentication.data.*
import com.rupaya.features.home.data.DashboardSummary
import com.rupaya.features.transactions.data.Transaction
import com.rupaya.features.transactions.data.Category
import com.rupaya.features.accounts.data.Account
import com.rupaya.features.analytics.data.Budget
import com.rupaya.features.analytics.data.Goal
import retrofit2.Response
import retrofit2.http.*

interface ApiService {
    // Authentication
    @POST("/api/v1/auth/signup")
    suspend fun signup(@Body request: SignupRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/signin")
    suspend fun signin(@Body request: SigninRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/logout")
    suspend fun logout(@Body request: LogoutRequest): Response<Unit>

    // Dashboard
    @GET("/api/v1/analytics/dashboard")
    suspend fun getDashboard(): Response<DashboardSummary>

    // Transactions
    @GET("/api/v1/transactions")
    suspend fun getTransactions(): Response<List<Transaction>>

    @POST("/api/v1/transactions")
    suspend fun createTransaction(@Body transaction: Transaction): Response<Transaction>

    // Accounts
    @GET("/api/v1/accounts")
    suspend fun getAccounts(): Response<List<Account>>

    // Categories
    @GET("/api/v1/categories")
    suspend fun getCategories(): Response<List<com.rupaya.features.transactions.data.Category>>

    // Budgets
    @GET("/api/v1/budgets")
    suspend fun getBudgets(): Response<List<Budget>>

    // Goals
    @GET("/api/v1/goals")
    suspend fun getGoals(): Response<List<Goal>>
}
