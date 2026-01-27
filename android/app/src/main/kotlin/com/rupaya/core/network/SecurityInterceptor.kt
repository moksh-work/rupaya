package com.rupaya.core.network

import android.content.Context
import android.os.Build
import com.rupaya.core.security.SecureStorage
import okhttp3.Interceptor
import okhttp3.Response
import java.util.UUID

class SecurityInterceptor(
    private val context: Context,
    private val secureStorage: SecureStorage
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()

        val request = original.newBuilder()
            .header("X-API-Version", "v1")
            .header("X-Device-ID", getDeviceId())
            .header("X-Request-ID", UUID.randomUUID().toString())
            .header("X-Timestamp", System.currentTimeMillis().toString())
            .apply {
                val accessToken = secureStorage.retrieveSecurely("access_token")
                if (accessToken != null) {
                    header("Authorization", "Bearer $accessToken")
                }
            }
            .build()

        return chain.proceed(request)
    }

    private fun getDeviceId(): String {
        return "${Build.DEVICE}_${Build.FINGERPRINT.hashCode()}"
    }
}
