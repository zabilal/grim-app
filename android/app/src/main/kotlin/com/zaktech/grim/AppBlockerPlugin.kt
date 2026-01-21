package com.zaktech.grim

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AppBlockerPlugin : MethodCallHandler {
    private var context: Context? = null

    companion object {
        const val CHANNEL = "com.zaktech.grim/app_blocker"
        
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            val plugin = AppBlockerPlugin()
            plugin.context = context
            channel.setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "hasUsageStatsPermission" -> {
                result.success(hasUsageStatsPermission())
            }
            "requestUsageStatsPermission" -> {
                result.success(requestUsageStatsPermission())
            }
            "startAppBlocker" -> {
                val blockedApps = call.argument<List<String>>("blockedApps")
                if (blockedApps != null) {
                    startAppBlocker(blockedApps)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "blockedApps cannot be null", null)
                }
            }
            "stopAppBlocker" -> {
                stopAppBlocker()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val application = context?.applicationContext ?: return false
            val appOpsManager = application.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOpsManager.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    application.packageName
                )
            } else {
                appOpsManager.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    application.packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    private fun requestUsageStatsPermission(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context?.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun startAppBlocker(blockedApps: List<String>) {
        try {
            AppBlockerService.startAppBlocker(context!!, blockedApps.toSet())
            println("Starting app blocker for apps: $blockedApps")
        } catch (e: Exception) {
            println("Error starting app blocker: $e")
        }
    }

    private fun stopAppBlocker() {
        try {
            AppBlockerService.stopAppBlocker(context!!)
            println("Stopping app blocker")
        } catch (e: Exception) {
            println("Error stopping app blocker: $e")
        }
    }
}
