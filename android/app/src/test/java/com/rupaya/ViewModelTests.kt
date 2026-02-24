/**
 * Android Unit Tests
 * Minimal test suite for app compilation
 * Testing workflows 02 and 03 with enterprise security controls
 */

package com.rupaya

import org.junit.Test

class ExampleUnitTest {
    @Test
    fun addition_isCorrect() {
        assert(2 + 2 == 4)
    }

    @Test
    fun stringValidation() {
        val email = "test@example.com"
        assert(email.contains("@"))
    }

    @Test
    fun numberFormatting() {
        val amount = 1234.56
        val formatted = String.format("%.2f", amount)
        assert(formatted == "1234.56")
    }

    @Test
    fun listOperations() {
        val numbers = listOf(1, 2, 3, 4, 5)
        assert(numbers.sum() == 15)
    }
}
