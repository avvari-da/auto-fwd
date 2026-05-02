package com.avvarida.autofwd

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object SmsForwardingConfigStore {
    private const val PREFERENCES_NAME = "sms_forwarding_config"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_ROUTES = "routes"
    private const val KEY_ID = "id"
    private const val KEY_NAME = "name"
    private const val KEY_SENDER_PATTERN = "senderPattern"
    private const val KEY_BODY_PATTERN = "bodyPattern"
    private const val KEY_DESTINATION_NUMBER = "destinationNumber"

    fun loadMap(context: Context): Map<String, Any> {
        val config = loadConfig(context)

        return mapOf(
            KEY_ENABLED to config.enabled,
            KEY_ROUTES to config.routes.map { route ->
                mapOf(
                    KEY_ID to route.id,
                    KEY_NAME to route.name,
                    KEY_ENABLED to route.enabled,
                    KEY_SENDER_PATTERN to route.senderPattern,
                    KEY_BODY_PATTERN to route.bodyPattern,
                    KEY_DESTINATION_NUMBER to route.destinationNumber,
                )
            },
        )
    }

    fun loadConfig(context: Context): SmsForwardingConfig {
        val preferences = context.getSharedPreferences(
            PREFERENCES_NAME,
            Context.MODE_PRIVATE,
        )
        val routesJson = preferences.getString(KEY_ROUTES, "[]").orEmpty()

        return SmsForwardingConfig(
            enabled = preferences.getBoolean(KEY_ENABLED, false),
            routes = routesFromJson(routesJson),
        )
    }

    fun save(context: Context, arguments: Map<*, *>) {
        val enabled = arguments[KEY_ENABLED] == true
        val routes = (arguments[KEY_ROUTES] as? List<*>).orEmpty()

        context
            .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putString(KEY_ROUTES, routesToJson(routes))
            .apply()
    }

    private fun routesFromJson(routesJson: String): List<SmsRouteConfig> {
        return try {
            val routes = JSONArray(routesJson)
            buildList {
                for (index in 0 until routes.length()) {
                    val route = routes.optJSONObject(index) ?: continue
                    add(
                        SmsRouteConfig(
                            id = route.optString(KEY_ID),
                            name = route.optString(KEY_NAME),
                            enabled = route.optBoolean(KEY_ENABLED, true),
                            senderPattern = route.optString(KEY_SENDER_PATTERN),
                            bodyPattern = route.optString(KEY_BODY_PATTERN),
                            destinationNumber = route.optString(KEY_DESTINATION_NUMBER),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun routesToJson(routes: List<*>): String {
        val jsonRoutes = JSONArray()

        routes.forEach { route ->
            val routeMap = route as? Map<*, *> ?: return@forEach
            jsonRoutes.put(
                JSONObject()
                    .put(KEY_ID, routeMap[KEY_ID] as? String ?: "")
                    .put(KEY_NAME, routeMap[KEY_NAME] as? String ?: "")
                    .put(KEY_ENABLED, routeMap[KEY_ENABLED] != false)
                    .put(KEY_SENDER_PATTERN, routeMap[KEY_SENDER_PATTERN] as? String ?: "")
                    .put(KEY_BODY_PATTERN, routeMap[KEY_BODY_PATTERN] as? String ?: "")
                    .put(
                        KEY_DESTINATION_NUMBER,
                        routeMap[KEY_DESTINATION_NUMBER] as? String ?: "",
                    ),
            )
        }

        return jsonRoutes.toString()
    }
}
