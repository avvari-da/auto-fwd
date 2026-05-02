package com.avvarida.autofwd

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SmsRuleMatcherTest {
    @Test
    fun matchesWhenSenderAndBodyPatternsBothMatch() {
        val route = SmsRouteConfig(
            id = "bank-otp",
            name = "Bank OTP",
            enabled = true,
            senderPattern = """^\+15551234567$""",
            bodyPattern = """OTP: \d{6}""",
            destinationNumber = "+15557654321",
        )

        assertTrue(
            SmsRuleMatcher.matches(
                route = route,
                sender = "+15551234567",
                body = "Your OTP: 123456",
            ),
        )
    }

    @Test
    fun matchesSenderAndBodyPatternsIgnoringCase() {
        val route = SmsRouteConfig(
            id = "bank-credit",
            name = "Bank Credit",
            enabled = true,
            senderPattern = "banksender",
            bodyPattern = "credited",
            destinationNumber = "+15557654321",
        )

        assertTrue(
            SmsRuleMatcher.matches(
                route = route,
                sender = "BankSender",
                body = "Your account was CREDITED",
            ),
        )
    }

    @Test
    fun doesNotMatchWhenForwardingIsDisabled() {
        val route = SmsRouteConfig(
            id = "bank-credit",
            name = "Bank Credit",
            enabled = false,
            senderPattern = "BankSender",
            bodyPattern = "credited",
            destinationNumber = "+15557654321",
        )

        assertFalse(
            SmsRuleMatcher.matches(
                route = route,
                sender = "BankSender",
                body = "Your account was credited",
            ),
        )
    }

    @Test
    fun doesNotMatchWhenSenderPatternDoesNotMatch() {
        val route = SmsRouteConfig(
            id = "bank-credit",
            name = "Bank Credit",
            enabled = true,
            senderPattern = "BankSender",
            bodyPattern = "credited",
            destinationNumber = "+15557654321",
        )

        assertFalse(
            SmsRuleMatcher.matches(
                route = route,
                sender = "OtherSender",
                body = "Your account was credited",
            ),
        )
    }

    @Test
    fun doesNotMatchWhenBodyPatternDoesNotMatch() {
        val route = SmsRouteConfig(
            id = "bank-credit",
            name = "Bank Credit",
            enabled = true,
            senderPattern = "BankSender",
            bodyPattern = "credited",
            destinationNumber = "+15557654321",
        )

        assertFalse(
            SmsRuleMatcher.matches(
                route = route,
                sender = "BankSender",
                body = "Your account was debited",
            ),
        )
    }

    @Test
    fun doesNotMatchInvalidRegexPatterns() {
        val route = SmsRouteConfig(
            id = "invalid",
            name = "Invalid",
            enabled = true,
            senderPattern = "[",
            bodyPattern = "credited",
            destinationNumber = "+15557654321",
        )

        assertFalse(
            SmsRuleMatcher.matches(
                route = route,
                sender = "BankSender",
                body = "Your account was credited",
            ),
        )
    }

    @Test
    fun doesNotMatchWhenDestinationIsBlank() {
        val route = SmsRouteConfig(
            id = "no-destination",
            name = "No Destination",
            enabled = true,
            senderPattern = "BankSender",
            bodyPattern = "credited",
            destinationNumber = " ",
        )

        assertFalse(
            SmsRuleMatcher.matches(
                route = route,
                sender = "BankSender",
                body = "Your account was credited",
            ),
        )
    }

    @Test
    fun matchingDestinationsReturnsEveryMatchingUniqueDestination() {
        val config = SmsForwardingConfig(
            enabled = true,
            routes = listOf(
                SmsRouteConfig(
                    id = "bank-credit-primary",
                    name = "Bank Credit Primary",
                    enabled = true,
                    senderPattern = "BankSender",
                    bodyPattern = "credited",
                    destinationNumber = "+15550000001",
                ),
                SmsRouteConfig(
                    id = "bank-credit-duplicate",
                    name = "Bank Credit Duplicate",
                    enabled = true,
                    senderPattern = "BankSender",
                    bodyPattern = "credited",
                    destinationNumber = " +15550000001 ",
                ),
                SmsRouteConfig(
                    id = "bank-credit-secondary",
                    name = "Bank Credit Secondary",
                    enabled = true,
                    senderPattern = "BankSender",
                    bodyPattern = "credited",
                    destinationNumber = "+15550000002",
                ),
                SmsRouteConfig(
                    id = "disabled-route",
                    name = "Disabled",
                    enabled = false,
                    senderPattern = "BankSender",
                    bodyPattern = "credited",
                    destinationNumber = "+15550000003",
                ),
            ),
        )

        val destinations = SmsRuleMatcher.matchingDestinations(
            config = config,
            sender = "banksender",
            body = "Your account was CREDITED",
        )

        assertTrue(destinations == listOf("+15550000001", "+15550000002"))
    }

    @Test
    fun matchingDestinationsReturnsEmptyWhenGlobalForwardingIsDisabled() {
        val config = SmsForwardingConfig(
            enabled = false,
            routes = listOf(
                SmsRouteConfig(
                    id = "bank-credit",
                    name = "Bank Credit",
                    enabled = true,
                    senderPattern = "BankSender",
                    bodyPattern = "credited",
                    destinationNumber = "+15550000001",
                ),
            ),
        )

        val destinations = SmsRuleMatcher.matchingDestinations(
            config = config,
            sender = "BankSender",
            body = "Your account was credited",
        )

        assertTrue(destinations.isEmpty())
    }
}
