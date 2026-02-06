package com.rupaya.features.analytics.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.core.network.ApiService
import com.rupaya.features.analytics.data.Budget
import com.rupaya.features.analytics.data.Goal
import com.rupaya.features.home.data.CategoryBreakdown
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AnalyticsViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _categoryBreakdown = MutableStateFlow<List<CategoryBreakdown>>(emptyList())
    val categoryBreakdown: StateFlow<List<CategoryBreakdown>> = _categoryBreakdown.asStateFlow()

    private val _budgets = MutableStateFlow<List<Budget>>(emptyList())
    val budgets: StateFlow<List<Budget>> = _budgets.asStateFlow()

    private val _goals = MutableStateFlow<List<Goal>>(emptyList())
    val goals: StateFlow<List<Goal>> = _goals.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            try {
                val dashboardResponse = apiService.getDashboard()
                if (dashboardResponse.isSuccessful) {
                    _categoryBreakdown.value = dashboardResponse.body()?.categoryBreakdown ?: emptyList()
                }

                val budgetsResponse = apiService.getBudgets()
                if (budgetsResponse.isSuccessful) {
                    _budgets.value = budgetsResponse.body() ?: emptyList()
                }

                val goalsResponse = apiService.getGoals()
                if (goalsResponse.isSuccessful) {
                    _goals.value = goalsResponse.body() ?: emptyList()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
