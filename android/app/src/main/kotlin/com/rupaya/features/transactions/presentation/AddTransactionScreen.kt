package com.rupaya.features.transactions.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddTransactionScreen(
    viewModel: AddTransactionViewModel = hiltViewModel(),
    onTransactionAdded: () -> Unit
) {
    var amount by remember { mutableStateOf("") }
    var transactionType by remember { mutableStateOf("expense") }
    var selectedAccountId by remember { mutableStateOf("") }
    var selectedCategoryId by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var selectedDate by remember { mutableStateOf(Date()) }

    val accounts by viewModel.accounts.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadAccountsAndCategories()
    }

    LaunchedEffect(accounts) {
        if (accounts.isNotEmpty() && selectedAccountId.isEmpty()) {
            selectedAccountId = accounts.first().accountId
        }
    }

    LaunchedEffect(categories) {
        if (categories.isNotEmpty() && selectedCategoryId.isEmpty()) {
            selectedCategoryId = categories.first().categoryId
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text("Add Transaction", style = MaterialTheme.typography.headlineSmall)

        // Transaction Type Selector
        Card {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Transaction Type", style = MaterialTheme.typography.titleSmall)
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = transactionType == "expense",
                        onClick = { transactionType = "expense" },
                        label = { Text("Expense") }
                    )
                    FilterChip(
                        selected = transactionType == "income",
                        onClick = { transactionType = "income" },
                        label = { Text("Income") }
                    )
                    FilterChip(
                        selected = transactionType == "transfer",
                        onClick = { transactionType = "transfer" },
                        label = { Text("Transfer") }
                    )
                }
            }
        }

        // Amount
        OutlinedTextField(
            value = amount,
            onValueChange = { amount = it },
            label = { Text("Amount") },
            leadingIcon = { Icon(Icons.Default.Star, contentDescription = null) },
            modifier = Modifier.fillMaxWidth()
        )

        // Account Selector
        if (accounts.isNotEmpty()) {
            var accountExpanded by remember { mutableStateOf(false) }
            ExposedDropdownMenuBox(
                expanded = accountExpanded,
                onExpandedChange = { accountExpanded = it }
            ) {
                OutlinedTextField(
                    value = accounts.find { it.accountId == selectedAccountId }?.name ?: "",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Account") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = accountExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable)
                )
                ExposedDropdownMenu(
                    expanded = accountExpanded,
                    onDismissRequest = { accountExpanded = false }
                ) {
                    accounts.forEach { account ->
                        DropdownMenuItem(
                            text = { Text(account.name) },
                            onClick = {
                                selectedAccountId = account.accountId
                                accountExpanded = false
                            }
                        )
                    }
                }
            }
        }

        // Category Selector
        if (categories.isNotEmpty()) {
            var categoryExpanded by remember { mutableStateOf(false) }
            ExposedDropdownMenuBox(
                expanded = categoryExpanded,
                onExpandedChange = { categoryExpanded = it }
            ) {
                OutlinedTextField(
                    value = categories.find { it.categoryId == selectedCategoryId }?.name ?: "",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Category") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable)
                )
                ExposedDropdownMenu(
                    expanded = categoryExpanded,
                    onDismissRequest = { categoryExpanded = false }
                ) {
                    categories.forEach { category ->
                        DropdownMenuItem(
                            text = { Text(category.name) },
                            onClick = {
                                selectedCategoryId = category.categoryId
                                categoryExpanded = false
                            }
                        )
                    }
                }
            }
        }

        // Notes
        OutlinedTextField(
            value = notes,
            onValueChange = { notes = it },
            label = { Text("Notes (optional)") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 2
        )

        Spacer(modifier = Modifier.weight(1f))

        // Submit Button
        Button(
            onClick = {
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                viewModel.createTransaction(
                    accountId = selectedAccountId,
                    categoryId = selectedCategoryId,
                    amount = amount.toDoubleOrNull() ?: 0.0,
                    transactionType = transactionType,
                    transactionDate = dateFormat.format(selectedDate),
                    merchant = notes.ifEmpty { "Manual Transaction" },
                    description = notes
                )
                onTransactionAdded()
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading && amount.toDoubleOrNull() != null && selectedAccountId.isNotEmpty() && selectedCategoryId.isNotEmpty()
        ) {
            if (isLoading) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp))
            } else {
                Text("Add Transaction")
            }
        }
    }
}
