package com.rupaya.features.accounts.data

import com.google.gson.annotations.SerializedName

data class Account(
    @SerializedName("account_id") val accountId: String = "",
    @SerializedName("user_id") val userId: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("account_type") val accountType: String = "",
    @SerializedName("currency") val currency: String = "USD",
    @SerializedName("current_balance") val currentBalance: Double = 0.0,
    @SerializedName("is_default") val isDefault: Boolean? = false
)
