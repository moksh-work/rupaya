package com.rupaya.features.authentication.data

import com.google.gson.annotations.SerializedName

data class SignupRequest(
    val email: String,
    val password: String,
    val deviceId: String,
    val deviceName: String
)

data class SignupPhoneRequest(
    val email: String,
    val phoneNumber: String,
    val otp: String,
    val deviceId: String,
    val deviceName: String,
    val name: String? = null
)

data class SigninRequest(
    val email: String,
    val password: String,
    val deviceId: String
)

data class SigninPhoneRequest(
    val phoneNumber: String,
    val otp: String,
    val deviceId: String
)

data class RefreshTokenRequest(
    val refreshToken: String
)

data class LogoutRequest(
    val refreshToken: String
)

data class PhoneOtpRequest(
    val phoneNumber: String,
    val purpose: String
)

data class OTPResponse(
    val message: String,
    val otp: String?
)

data class AuthenticationResponse(
    val userId: String,
    val accessToken: String,
    val refreshToken: String,
    val user: User,
    val mfaRequired: Boolean? = null
)

data class User(
    val id: String,
    val email: String,
    @SerializedName("phoneNumber") val phoneNumber: String?,
    @SerializedName("phoneVerified") val phoneVerified: Boolean?,
    val name: String,
    val currency: String,
    val timezone: String,
    val theme: String,
    val language: String
)
