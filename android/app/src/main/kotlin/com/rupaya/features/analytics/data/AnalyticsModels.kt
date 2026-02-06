package com.rupaya.features.analytics.data

import com.google.gson.annotations.SerializedName

data class Budget(
    @SerializedName("budget_id") val budgetId: String = "",
    @SerializedName("category_id") val categoryId: String? = null,
    @SerializedName("category_name") val categoryName: String? = null,
    @SerializedName("limit") val limit: Double = 0.0,
    @SerializedName("spent") val spent: Double = 0.0,
    @SerializedName("period") val period: String = "month"
)

data class Goal(
    @SerializedName("goal_id") val goalId: String = "",
    @SerializedName("goal_name") val goalName: String = "",
    @SerializedName("target_amount") val targetAmount: Double = 0.0,
    @SerializedName("current_amount") val currentAmount: Double = 0.0,
    @SerializedName("target_date") val targetDate: String? = null
)
