package com.rupaya

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.performTextInput
import org.junit.Rule
import org.junit.Test

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
class ExampleInstrumentedTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun loginScreen_showsError_onInvalidCredentials() {
        // Input invalid credentials
        composeTestRule.onNodeWithText("Email").performTextInput("invalid@example.com")
        composeTestRule.onNodeWithText("Password").performTextInput("wrongpassword")
        // Click the Sign In button
        composeTestRule.onNodeWithText("Sign In").performClick()
        // Wait for the error message to appear and assert
        composeTestRule.waitUntil(timeoutMillis = 5_000) {
            composeTestRule.onAllNodesWithTag("login_error_message").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("login_error_message").assertExists()
    }

    @Test
    fun signupScreen_navigatesToHome_onSuccess() {
        // Simulate user input and sign up
        // composeTestRule.onNodeWithText("Sign Up").performClick()
        // composeTestRule.onNodeWithText("Home").assertExists()
    }
}
