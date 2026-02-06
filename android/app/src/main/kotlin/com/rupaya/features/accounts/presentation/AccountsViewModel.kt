package com.rupaya.features.accounts.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.core.network.ApiService
import com.rupaya.features.accounts.data.Account
import com.rupaya.features.transactions.data.Transaction
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AccountsViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _accounts = MutableStateFlow<List<Account>>(emptyList())
    val accounts: StateFlow<List<Account>> = _accounts.asStateFlow()

    private val _transactions = MutableStateFlow<List<Transaction>>(emptyList())
    val transactions: StateFlow<List<Transaction>> = _transactions.asStateFlow()

    fun loadAccounts() {
        viewModelScope.launch {
            try {
                val accountsResponse = apiService.getAccounts()
                if (accountsResponse.isSuccessful) {
                    _accounts.value = accountsResponse.body() ?: emptyList()
                }

                val transactionsResponse = apiService.getTransactions()
                if (transactionsResponse.isSuccessful) {
                    _transactions.value = transactionsResponse.body() ?: emptyList()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
