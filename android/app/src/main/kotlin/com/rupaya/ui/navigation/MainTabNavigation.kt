package com.rupaya.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import com.rupaya.features.accounts.presentation.AccountsScreen
import com.rupaya.features.analytics.presentation.InsightsScreen
import com.rupaya.features.home.presentation.HomeScreen
import com.rupaya.features.settings.presentation.SettingsScreen
import com.rupaya.features.transactions.presentation.AddTransactionScreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainTabNavigation(
    onLogout: () -> Unit
) {
    var selectedTab by remember { mutableStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                BottomNavItem.values().forEachIndexed { index, item ->
                    NavigationBarItem(
                        icon = { Icon(item.icon, contentDescription = item.label) },
                        label = { Text(item.label) },
                        selected = selectedTab == index,
                        onClick = { selectedTab = index }
                    )
                }
            }
        }
    ) { paddingValues ->
        when (selectedTab) {
            0 -> HomeScreen(
                modifier = Modifier.padding(paddingValues),
                onNavigateToTransactions = { selectedTab = 3 },
                onNavigateToAdd = { selectedTab = 2 }
            )
            1 -> InsightsScreen()
            2 -> AddTransactionScreen(onTransactionAdded = { selectedTab = 0 })
            3 -> AccountsScreen()
            4 -> SettingsScreen(onLogout = onLogout)
        }
    }
}

enum class BottomNavItem(val label: String, val icon: ImageVector) {
    Home("Home", Icons.Default.Home),
    Insights("Insights", Icons.Default.Star),
    Add("Add", Icons.Default.AddCircle),
    Accounts("Accounts", Icons.Default.AccountCircle),
    Settings("Settings", Icons.Default.Settings)
}
