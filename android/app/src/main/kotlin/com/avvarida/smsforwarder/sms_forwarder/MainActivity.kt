package com.avvarida.autofwd

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadConfig" -> result.success(SmsForwardingConfigStore.loadMap(this))
                "saveConfig" -> saveConfig(call, result)
                "getPermissionStatus" -> result.success(permissionStatus())
                "requestSmsPermissions" -> requestSmsPermissions(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != SMS_PERMISSION_REQUEST_CODE) {
            return
        }

        pendingPermissionResult?.success(permissionStatus())
        pendingPermissionResult = null
    }

    private fun saveConfig(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>

        if (arguments == null) {
            result.error("invalid_arguments", "Expected config map.", null)
            return
        }

        SmsForwardingConfigStore.save(this, arguments)
        result.success(null)
    }

    private fun requestSmsPermissions(result: MethodChannel.Result) {
        if (hasSmsPermissions()) {
            result.success(PERMISSION_GRANTED)
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "An SMS permission request is already in progress.",
                null,
            )
            return
        }

        pendingPermissionResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(SMS_PERMISSIONS, SMS_PERMISSION_REQUEST_CODE)
        } else {
            result.success(PERMISSION_GRANTED)
            pendingPermissionResult = null
        }
    }

    private fun permissionStatus(): String {
        return if (hasSmsPermissions()) PERMISSION_GRANTED else PERMISSION_DENIED
    }

    private fun hasSmsPermissions(): Boolean {
        return SMS_PERMISSIONS.all { permission ->
            Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    private companion object {
        const val CHANNEL_NAME = "sms_forwarder/config"
        const val PERMISSION_GRANTED = "granted"
        const val PERMISSION_DENIED = "denied"
        const val SMS_PERMISSION_REQUEST_CODE = 2701

        val SMS_PERMISSIONS = arrayOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.SEND_SMS,
        )
    }
}
