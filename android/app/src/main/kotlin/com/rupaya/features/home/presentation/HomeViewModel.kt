package com.rupaya.features.home.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.core.network.ApiService
import com.rupaya.features.home.data.DashboardSummary
import com.rupaya.features.transactions.data.Transaction
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _dashboard = MutableStateFlow<DashboardSummary?>(null)
    val dashboard: StateFlow<DashboardSummary?> = _dashboard.asStateFlow()

    private val _recentTransactions = MutableStateFlow<List<Transaction>>(emptyList())
    val recentTransactions: StateFlow<List<Transaction>> = _recentTransactions.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val dashboardResponse = apiService.getDashboard()
                if (dashboardResponse.isSuccessful) {
                    _dashboard.value = dashboardResponse.body()
                }

                val transactionsResponse = apiService.getTransactions()
                if (transactionsResponse.isSuccessful) {
                    _recentTransactions.value = transactionsResponse.body() ?: emptyList()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isLoading.value = false
            }
        }
    }
}
