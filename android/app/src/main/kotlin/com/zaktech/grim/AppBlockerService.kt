package com.zaktech.grim

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import android.content.pm.PackageManager
import android.app.ActivityManager
import android.widget.Toast

class AppBlockerService : Service() {
    
    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false
    private val blockedApps = mutableSetOf<String>()
    
    companion object {
        private const val TAG = "AppBlockerService"
        
        // Default blocked apps package names
        private val DEFAULT_BLOCKED_APPS = setOf(
            "com.facebook.katana",           // Facebook
            "com.instagram.android",        // Instagram
            "com.twitter.android",          // Twitter
            "com.tiktok",                   // TikTok
            "com.snapchat.android",         // Snapchat
            "com.reddit.frontpage",         // Reddit
            "com.whatsapp",                 // WhatsApp
            "com.discord",                  // Discord
            "com.linkedin.android",        // LinkedIn
            "com.pinterest",                // Pinterest
            "com.spotify.music",            // Spotify
            "com.netflix.mediaclient",      // Netflix
            "com.youtube.android",          // YouTube
            "com.google.android.youtube",   // YouTube (alternative)
            "com.zhiliaoapp.musically",     // TikTok (alternative)
        )
        
        fun startAppBlocker(context: Context, customBlockedApps: Set<String>? = null) {
            val intent = Intent(context, AppBlockerService::class.java)
            intent.putExtra("blocked_apps", customBlockedApps?.toTypedArray() ?: DEFAULT_BLOCKED_APPS.toTypedArray())
            context.startForegroundService(intent)
        }
        
        fun stopAppBlocker(context: Context) {
            val intent = Intent(context, AppBlockerService::class.java)
            context.stopService(intent)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AppBlockerService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AppBlockerService started")
        
        // Get blocked apps from intent
        val blockedAppsArray = intent?.getStringArrayExtra("blocked_apps")
        if (blockedAppsArray != null) {
            blockedApps.clear()
            blockedApps.addAll(blockedAppsArray)
        } else {
            blockedApps.addAll(DEFAULT_BLOCKED_APPS)
        }
        
        if (!isRunning) {
            isRunning = true
            startAppMonitoring()
        }
        
        return START_STICKY
    }
    
    private fun startAppMonitoring() {
        val runnable = object : Runnable {
            override fun run() {
                if (isRunning) {
                    checkAndBlockApps()
                    handler.postDelayed(this, 1000) // Check every second
                }
            }
        }
        handler.post(runnable)
    }
    
    private fun checkAndBlockApps() {
        try {
            val currentApp = getCurrentForegroundApp()
            if (currentApp != null && blockedApps.contains(currentApp)) {
                Log.d(TAG, "Blocked app detected: $currentApp")
                blockAppAndShowWarning(currentApp)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking apps: ${e.message}")
        }
    }
    
    private fun getCurrentForegroundApp(): String? {
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val currentTime = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                currentTime - 1000 * 10, // Last 10 seconds
                currentTime
            )
            
            var foregroundApp: String? = null
            var lastTime = 0L
            
            for (stat in stats) {
                if (stat.lastTimeUsed > lastTime) {
                    lastTime = stat.lastTimeUsed
                    foregroundApp = stat.packageName
                }
            }
            
            foregroundApp
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}")
            null
        }
    }
    
    private fun blockAppAndShowWarning(packageName: String) {
        try {
            // Get app name for display
            val appName = getAppName(packageName)
            
            // Show toast warning
            handler.post {
                Toast.makeText(
                    this,
                    "Strict Mode: $appName is blocked during deep work!",
                    Toast.LENGTH_LONG
                ).show()
            }
            
            // Return to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(homeIntent)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error blocking app: ${e.message}")
        }
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacksAndMessages(null)
        Log.d(TAG, "AppBlockerService destroyed")
    }
}
