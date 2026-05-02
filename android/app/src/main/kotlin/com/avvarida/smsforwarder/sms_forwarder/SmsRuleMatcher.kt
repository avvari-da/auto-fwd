package com.avvarida.autofwd

data class SmsForwardingConfig(
    val enabled: Boolean,
    val routes: List<SmsRouteConfig>,
)

data class SmsRouteConfig(
    val id: String,
    val name: String,
    val enabled: Boolean,
    val senderPattern: String,
    val bodyPattern: String,
    val destinationNumber: String,
)

object SmsRuleMatcher {
    fun matches(
        route: SmsRouteConfig,
        sender: String,
        body: String,
    ): Boolean {
        if (!route.enabled || route.destinationNumber.isBlank()) {
            return false
        }

        val senderRegex = route.senderPattern.toRegexOrNull() ?: return false
        val bodyRegex = route.bodyPattern.toRegexOrNull() ?: return false

        return senderRegex.containsMatchIn(sender) && bodyRegex.containsMatchIn(body)
    }

    fun matchingDestinations(
        config: SmsForwardingConfig,
        sender: String,
        body: String,
    ): List<String> {
        if (!config.enabled) {
            return emptyList()
        }

        return config.routes
            .asSequence()
            .filter { route -> matches(route, sender, body) }
            .map { route -> route.destinationNumber.trim() }
            .distinct()
            .toList()
    }

    private fun String.toRegexOrNull(): Regex? {
        if (isBlank()) {
            return null
        }

        return try {
            trim().toRegex(RegexOption.IGNORE_CASE)
        } catch (_: IllegalArgumentException) {
            null
        }
    }
}
