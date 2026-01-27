package com.rupaya.features.authentication.data

import com.google.gson.annotations.SerializedName

data class SignupRequest(
    val email: String,
    val password: String,
    val deviceId: String,
    val deviceName: String
)

data class SigninRequest(
    val email: String,
    val password: String,
    val deviceId: String
)

data class RefreshTokenRequest(
    val refreshToken: String
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
    val name: String,
    val currency: String,
    val timezone: String,
    val theme: String,
    val language: String
)
