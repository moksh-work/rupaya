package com.rupaya.features.transactions.data

import com.google.gson.annotations.SerializedName

data class Transaction(
    @SerializedName("transaction_id") val transactionId: String = "",
    @SerializedName("account_id") val accountId: String = "",
    @SerializedName("category_id") val categoryId: String = "",
    @SerializedName("amount") val amount: Double = 0.0,
    @SerializedName("transaction_type") val transactionType: String = "expense",
    @SerializedName("transaction_date") val transactionDate: String = "",
    @SerializedName("merchant") val merchant: String? = null,
    @SerializedName("description") val description: String? = null,
    @SerializedName("created_at") val createdAt: String? = null
)

data class Category(
    @SerializedName("category_id") val categoryId: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("category_type") val categoryType: String = "",
    @SerializedName("icon") val icon: String? = null,
    @SerializedName("color") val color: String? = null
)
