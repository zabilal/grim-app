package com.zaktech.grim

import android.app.Service
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.app.ActivityManager
import android.widget.Toast
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.KeyEvent
import android.view.WindowManager
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Build

class AppBlockerService : Service() {
    
    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false
    private val blockedApps = mutableSetOf<String>()
    private var isNavigationBlocking = false
    private var navigationBlockReceiver: BroadcastReceiver? = null
    
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
        
        fun startNavigationBlock(context: Context) {
            val intent = Intent(context, AppBlockerService::class.java)
            intent.action = "START_NAVIGATION_BLOCK"
            context.startService(intent)
        }
        
        fun stopNavigationBlock(context: Context) {
            val intent = Intent(context, AppBlockerService::class.java)
            intent.action = "STOP_NAVIGATION_BLOCK"
            context.startService(intent)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AppBlockerService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AppBlockerService started")
        
        // Handle different actions
        when (intent?.action) {
            "START_NAVIGATION_BLOCK" -> {
                startNavigationBlocking()
                return START_STICKY
            }
            "STOP_NAVIGATION_BLOCK" -> {
                stopNavigationBlocking()
                return START_NOT_STICKY
            }
        }
        
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
        isNavigationBlocking = false
        navigationBlockReceiver?.let { unregisterReceiver(it) }
        handler.removeCallbacksAndMessages(null)
        Log.d(TAG, "AppBlockerService destroyed")
    }
    
    private fun startNavigationBlocking() {
        if (isNavigationBlocking) return
        
        isNavigationBlocking = true
        Log.d(TAG, "Starting navigation blocking")
        
        // Register broadcast receiver to intercept home button and recent apps
        navigationBlockReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_CLOSE_SYSTEM_DIALOGS -> {
                        // User pressed home or recent apps button
                        Log.d(TAG, "Navigation button pressed - blocking")
                        // Show our app again
                        val bringToFrontIntent = Intent(context, MainActivity::class.java)
                        bringToFrontIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        context?.startActivity(bringToFrontIntent)
                    }
                }
            }
        }
        
        val filter = IntentFilter()
        filter.addAction(Intent.ACTION_CLOSE_SYSTEM_DIALOGS)
        registerReceiver(navigationBlockReceiver, filter)
        
        // Show persistent overlay that blocks navigation
        showNavigationBlockOverlay()
    }
    
    private fun stopNavigationBlocking() {
        if (!isNavigationBlocking) return
        
        isNavigationBlocking = false
        Log.d(TAG, "Stopping navigation blocking")
        
        navigationBlockReceiver?.let { unregisterReceiver(it) }
        navigationBlockReceiver = null
        
        // Hide overlay
        hideNavigationBlockOverlay()
    }
    
    private fun showNavigationBlockOverlay() {
        try {
            val intent = Intent(this, FullscreenReminderActivity::class.java)
            intent.putExtra("navigation_block", true)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing navigation block overlay: ${e.message}")
        }
    }
    
    private fun hideNavigationBlockOverlay() {
        try {
            val intent = Intent(this, FullscreenReminderActivity::class.java)
            intent.action = "HIDE_OVERLAY"
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding navigation block overlay: ${e.message}")
        }
    }
}
