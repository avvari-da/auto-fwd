package com.avvarida.autofwd

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) {
            return
        }

        val sender = messages.firstNotNullOfOrNull { it.originatingAddress }.orEmpty()
        val body = messages.joinToString(separator = "") { it.messageBody.orEmpty() }
        val config = SmsForwardingConfigStore.loadConfig(context)
        val destinations = SmsRuleMatcher.matchingDestinations(config, sender, body)

        destinations.forEach { destinationNumber ->
            sendSms(context, destinationNumber, body)
        }
    }

    private fun sendSms(context: Context, destinationNumber: String, body: String) {
        val smsManager = smsManager(context)
        val messageParts = smsManager.divideMessage(body)

        if (messageParts.size > 1) {
            smsManager.sendMultipartTextMessage(
                destinationNumber,
                null,
                messageParts,
                null,
                null,
            )
            return
        }

        smsManager.sendTextMessage(destinationNumber, null, body, null, null)
    }

    private fun smsManager(context: Context): SmsManager {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }
    }
}
