package com.rupaya.features.accounts.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountsScreen(
    viewModel: AccountsViewModel = hiltViewModel()
) {
    val accounts by viewModel.accounts.collectAsState()
    val transactions by viewModel.transactions.collectAsState()
    var selectedAccountId by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        viewModel.loadAccounts()
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Account Filter Row
        PrimaryScrollableTabRow(
            selectedTabIndex = accounts.indexOfFirst { it.accountId == selectedAccountId }.takeIf { it >= 0 } ?: 0,
            modifier = Modifier.fillMaxWidth()
        ) {
            Tab(
                selected = selectedAccountId == null,
                onClick = { selectedAccountId = null },
                text = { Text("All") }
            )
            accounts.forEach { account ->
                Tab(
                    selected = selectedAccountId == account.accountId,
                    onClick = { selectedAccountId = account.accountId },
                    text = { Text(account.name) }
                )
            }
        }

        // Transactions List
        val filteredTransactions = if (selectedAccountId == null) {
            transactions
        } else {
            transactions.filter { it.accountId == selectedAccountId }
        }

        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(filteredTransactions) { transaction ->
                TransactionCard(transaction)
            }
        }
    }
}

@Composable
fun TransactionCard(transaction: com.rupaya.features.transactions.data.Transaction) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
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
