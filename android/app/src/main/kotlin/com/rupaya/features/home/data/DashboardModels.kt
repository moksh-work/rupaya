package com.rupaya.features.home.data

import com.google.gson.annotations.SerializedName

data class DashboardSummary(
    @SerializedName("total_balance") val totalBalance: Double? = 0.0,
    @SerializedName("income") val income: Double? = 0.0,
    @SerializedName("expenses") val expenses: Double? = 0.0,
    @SerializedName("savings") val savings: Double? = 0.0,
    @SerializedName("savings_rate") val savingsRate: Double? = 0.0,
    @SerializedName("category_breakdown") val categoryBreakdown: List<CategoryBreakdown>? = emptyList()
)

data class CategoryBreakdown(
    val category: String,
    val amount: Double,
    val percentage: Double
)
