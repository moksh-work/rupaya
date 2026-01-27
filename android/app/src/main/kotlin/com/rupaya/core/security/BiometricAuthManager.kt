package com.rupaya.core.security

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.util.concurrent.Executor

class BiometricAuthManager(
    private val context: Context,
    private val executor: Executor,
    private val activity: FragmentActivity
) {
    private var biometricPrompt: BiometricPrompt? = null

    fun isBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(context)
        return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE,
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE,
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> false
            else -> false
        }
    }

    fun authenticate(callback: BiometricCallback) {
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authenticate to RUPAYA")
            .setSubtitle("Use your biometric to access")
            .setNegativeButtonText("Use PIN instead")
            .build()

        biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    callback.onSuccess()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    callback.onError(errString.toString())
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    callback.onFailed()
                }
            }
        )

        biometricPrompt?.authenticate(promptInfo)
    }

    interface BiometricCallback {
        fun onSuccess()
        fun onError(error: String)
        fun onFailed()
    }
}
