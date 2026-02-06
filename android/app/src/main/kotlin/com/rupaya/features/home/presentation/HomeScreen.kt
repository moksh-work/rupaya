package com.rupaya.features.home.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    modifier: Modifier = Modifier,
    viewModel: HomeViewModel = hiltViewModel(),
    onNavigateToTransactions: () -> Unit,
    onNavigateToAdd: () -> Unit
) {
    val dashboard by viewModel.dashboard.collectAsState()
    val recentTransactions by viewModel.recentTransactions.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadData()
    }

    Column(modifier = modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Balance Header Card
            item {
                BalanceHeaderCard(balance = dashboard?.totalBalance ?: 0.0)
            }

            // Quick Actions
            item {
                QuickActionsBar(onAddClick = onNavigateToAdd)
            }

            // Summary Cards
            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Summary", style = MaterialTheme.typography.titleMedium)
                    SummaryCard("Income", dashboard?.income ?: 0.0, Color(0xFF4CAF50), Icons.Default.Add)
                    SummaryCard("Expenses", dashboard?.expenses ?: 0.0, Color(0xFFF44336), Icons.Default.Delete)
                    SummaryCard("Net Savings", dashboard?.savings ?: 0.0, Color(0xFF2196F3), Icons.Default.AccountCircle)
                }
            }

            // Recent Transactions
            if (recentTransactions.isNotEmpty()) {
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Recent Transactions", style = MaterialTheme.typography.titleMedium)
                        TextButton(onClick = onNavigateToTransactions) {
                            Text("See all")
                        }
                    }
                }

                items(recentTransactions.take(5)) { transaction ->
                    TransactionRow(transaction)
                }
            }
        }
    }
}

@Composable
fun BalanceHeaderCard(balance: Double) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                "Total Balance",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
            Text(
                NumberFormat.getCurrencyInstance(Locale.US).format(balance),
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun QuickActionsBar(onAddClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        QuickActionButton("Expense", Color(0xFFFEEBEE), Color(0xFFF44336), Icons.Default.Delete, Modifier.weight(1f), onAddClick)
        QuickActionButton("Income", Color(0xFFE8F5E9), Color(0xFF4CAF50), Icons.Default.Add, Modifier.weight(1f), onAddClick)
        QuickActionButton("Transfer", Color(0xFFFFF3E0), Color(0xFFFF9800), Icons.Default.Star, Modifier.weight(1f), onAddClick)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickActionButton(label: String, bgColor: Color, iconColor: Color, icon: androidx.compose.ui.graphics.vector.ImageVector, modifier: Modifier, onClick: () -> Unit) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = bgColor),
        onClick = onClick
    ) {
        Column(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(icon, contentDescription = label, tint = iconColor)
            Spacer(modifier = Modifier.height(4.dp))
            Text(label, style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
fun SummaryCard(title: String, amount: Double, color: Color, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(title, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f))
                Text(NumberFormat.getCurrencyInstance(Locale.US).format(amount), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            Surface(
                shape = androidx.compose.foundation.shape.CircleShape,
                color = color.copy(alpha = 0.2f),
                modifier = Modifier.size(40.dp)
            ) {
                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                    Icon(icon, contentDescription = title, tint = color, modifier = Modifier.size(20.dp))
                }
            }
        }
    }
}

@Composable
fun TransactionRow(transaction: com.rupaya.features.transactions.data.Transaction) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(transaction.merchant ?: "Transaction", style = MaterialTheme.typography.titleSmall)
                Text(transaction.transactionDate, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
            }
            Text(
                NumberFormat.getCurrencyInstance(Locale.US).format(transaction.amount),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}
