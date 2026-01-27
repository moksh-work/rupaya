package com.rupaya.features.authentication.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.core.security.SecureStorage
import com.rupaya.features.authentication.data.AuthenticationApi
import com.rupaya.features.authentication.data.SigninRequest
import com.rupaya.features.authentication.data.SignupRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authApi: AuthenticationApi,
    private val secureStorage: SecureStorage
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _authError = MutableStateFlow<String?>(null)
    val authError: StateFlow<String?> = _authError.asStateFlow()

    init {
        checkAuthenticationStatus()
    }

    fun login(email: String, password: String, deviceId: String) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                _authError.value = null

                val request = SigninRequest(
                    email = email,
                    password = password,
                    deviceId = deviceId
                )

                val response = authApi.signin(request)

                if (response.isSuccessful && response.body() != null) {
                    val authResponse = response.body()!!
                    
                    // Save tokens securely
                    secureStorage.saveSecurely("access_token", authResponse.accessToken)
                    secureStorage.saveSecurely("refresh_token", authResponse.refreshToken)
                    secureStorage.saveSecurely("user_id", authResponse.userId)

                    _isAuthenticated.value = true
                } else {
                    _authError.value = response.message() ?: "Login failed"
                }
            } catch (e: Exception) {
                Timber.e(e)
                _authError.value = e.message ?: "Unknown error occurred"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun signup(email: String, password: String, deviceId: String, deviceName: String) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                _authError.value = null

                if (!validatePasswordStrength(password)) {
                    _authError.value = "Password is too weak"
                    _isLoading.value = false
                    return@launch
                }

                val request = SignupRequest(
                    email = email,
                    password = password,
                    deviceId = deviceId,
                    deviceName = deviceName
                )

                val response = authApi.signup(request)

                if (response.isSuccessful && response.body() != null) {
                    val authResponse = response.body()!!
                    
                    // Save tokens securely
                    secureStorage.saveSecurely("access_token", authResponse.accessToken)
                    secureStorage.saveSecurely("refresh_token", authResponse.refreshToken)
                    secureStorage.saveSecurely("user_id", authResponse.userId)

                    _isAuthenticated.value = true
                } else {
                    _authError.value = response.message() ?: "Signup failed"
                }
            } catch (e: Exception) {
                Timber.e(e)
                _authError.value = e.message ?: "Unknown error occurred"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun checkAuthenticationStatus() {
        val accessToken = secureStorage.retrieveSecurely("access_token")
        _isAuthenticated.value = accessToken != null
    }

    fun logout() {
        secureStorage.delete("access_token")
        secureStorage.delete("refresh_token")
        secureStorage.delete("user_id")
        _isAuthenticated.value = false
    }

    private fun validatePasswordStrength(password: String): Boolean {
        val patterns = listOf(
            "^.{12,}$",         // Minimum 12 characters
            "[A-Z]",            // Uppercase
            "[a-z]",            // Lowercase
            "[0-9]",            // Digit
            "[^A-Za-z0-9]"      // Special character
        )

        return patterns.all { pattern ->
            password.contains(Regex(pattern))
        }
    }
}
