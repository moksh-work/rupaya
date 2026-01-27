package com.rupaya.features.authentication.data

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthenticationApi {
    @POST("/api/v1/auth/signup")
    suspend fun signup(@Body request: SignupRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/signin")
    suspend fun signin(@Body request: SigninRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<AuthenticationResponse>

    @POST("/api/v1/auth/logout")
    suspend fun logout(): Response<Unit>
}
