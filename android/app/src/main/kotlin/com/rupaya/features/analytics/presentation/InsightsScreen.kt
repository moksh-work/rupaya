package com.rupaya.features.analytics.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    viewModel: AnalyticsViewModel = hiltViewModel()
) {
    var selectedTab by remember { mutableStateOf(0) }
    val categoryBreakdown by viewModel.categoryBreakdown.collectAsState()
    val budgets by viewModel.budgets.collectAsState()
    val goals by viewModel.goals.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadData()
    }

    Column(modifier = Modifier.fillMaxSize()) {
        PrimaryTabRow(selectedTabIndex = selectedTab) {
            Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("Analytics") })
            Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("Budgets") })
            Tab(selected = selectedTab == 2, onClick = { selectedTab = 2 }, text = { Text("Goals") })
            Tab(selected = selectedTab == 3, onClick = { selectedTab = 3 }, text = { Text("Reports") })
        }

        when (selectedTab) {
            0 -> AnalyticsTab(categoryBreakdown)
            1 -> BudgetsTab(budgets)
            2 -> GoalsTab(goals)
            3 -> ReportsTab(categoryBreakdown)
        }
    }
}

@Composable
fun AnalyticsTab(breakdown: List<com.rupaya.features.home.data.CategoryBreakdown>) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Spending by Category", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }

        items(breakdown) { item ->
            CategoryBreakdownCard(item)
        }
    }
}

@Composable
fun CategoryBreakdownCard(item: com.rupaya.features.home.data.CategoryBreakdown) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(item.category, style = MaterialTheme.typography.titleSmall)
                Text(NumberFormat.getCurrencyInstance(Locale.US).format(item.amount), fontWeight = FontWeight.SemiBold)
            }
            Spacer(modifier = Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { (item.percentage / 100).toFloat() },
                modifier = Modifier.fillMaxWidth().height(8.dp),
                color = Color(0xFF2196F3)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text("${item.percentage}%", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
        }
    }
}

@Composable
fun BudgetsTab(budgets: List<com.rupaya.features.analytics.data.Budget>) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Monthly Budgets", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }

        items(budgets) { budget ->
            BudgetCard(budget)
        }
    }
}

@Composable
fun BudgetCard(budget: com.rupaya.features.analytics.data.Budget) {
    val progress = (budget.spent / budget.limit).coerceIn(0.0, 1.0)
    val color = when {
        progress > 1.0 -> Color(0xFFF44336)
        progress > 0.8 -> Color(0xFFFF9800)
        else -> Color(0xFF4CAF50)
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(budget.categoryName ?: "Budget", style = MaterialTheme.typography.titleSmall)
                Text(
                    "${NumberFormat.getCurrencyInstance(Locale.US).format(budget.spent)} / ${NumberFormat.getCurrencyInstance(Locale.US).format(budget.limit)}",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { progress.toFloat() },
                modifier = Modifier.fillMaxWidth().height(10.dp),
                color = color
            )
        }
    }
}

@Composable
fun GoalsTab(goals: List<com.rupaya.features.analytics.data.Goal>) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Financial Goals", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }

        items(goals) { goal ->
            GoalCard(goal)
        }
    }
}

@Composable
fun GoalCard(goal: com.rupaya.features.analytics.data.Goal) {
    val progress = (goal.currentAmount / goal.targetAmount).coerceIn(0.0, 1.0)

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(goal.goalName, style = MaterialTheme.typography.titleSmall)
                Text(
                    "${NumberFormat.getCurrencyInstance(Locale.US).format(goal.currentAmount)} / ${NumberFormat.getCurrencyInstance(Locale.US).format(goal.targetAmount)}",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { progress.toFloat() },
                modifier = Modifier.fillMaxWidth().height(10.dp),
                color = Color(0xFF2196F3)
            )
            goal.targetDate?.let {
                Spacer(modifier = Modifier.height(4.dp))
                Text("Target: $it", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
            }
        }
    }
}

@Composable
fun ReportsTab(breakdown: List<com.rupaya.features.home.data.CategoryBreakdown>) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Period Reports", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }

        items(breakdown) { item ->
            CategoryBreakdownCard(item)
        }
    }
}
