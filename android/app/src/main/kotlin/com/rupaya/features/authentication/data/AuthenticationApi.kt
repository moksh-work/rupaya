package com.rupaya.features.authentication.data

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthenticationApi {
    @POST("/api/v1/auth/signup")
    suspend fun signup(@Body request: SignupRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/signup-phone")
    suspend fun signupPhone(@Body request: SignupPhoneRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/signin")
    suspend fun signin(@Body request: SigninRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/signin-phone")
    suspend fun signinPhone(@Body request: SigninPhoneRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/otp/request")
    suspend fun requestOtp(@Body request: PhoneOtpRequest): Response<OTPResponse>

    @POST("/api/v1/auth/logout")
    suspend fun logout(@Body request: LogoutRequest): Response<Unit>
}
