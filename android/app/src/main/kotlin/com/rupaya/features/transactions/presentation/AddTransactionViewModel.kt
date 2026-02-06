package com.rupaya.features.transactions.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.core.network.ApiService
import com.rupaya.features.accounts.data.Account
import com.rupaya.features.transactions.data.Category
import com.rupaya.features.transactions.data.Transaction
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AddTransactionViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _accounts = MutableStateFlow<List<Account>>(emptyList())
    val accounts: StateFlow<List<Account>> = _accounts.asStateFlow()

    private val _categories = MutableStateFlow<List<Category>>(emptyList())
    val categories: StateFlow<List<Category>> = _categories.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun loadAccountsAndCategories() {
        viewModelScope.launch {
            try {
                val accountsResponse = apiService.getAccounts()
                if (accountsResponse.isSuccessful) {
                    _accounts.value = accountsResponse.body() ?: emptyList()
                }

                val categoriesResponse = apiService.getCategories()
                if (categoriesResponse.isSuccessful) {
                    _categories.value = categoriesResponse.body() ?: emptyList()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun createTransaction(
        accountId: String,
        categoryId: String,
        amount: Double,
        transactionType: String,
        transactionDate: String,
        merchant: String,
        description: String
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val transaction = Transaction(
                    accountId = accountId,
                    categoryId = categoryId,
                    amount = amount,
                    transactionType = transactionType,
                    transactionDate = transactionDate,
                    merchant = merchant,
                    description = description
                )
                apiService.createTransaction(transaction)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isLoading.value = false
            }
        }
    }
}
