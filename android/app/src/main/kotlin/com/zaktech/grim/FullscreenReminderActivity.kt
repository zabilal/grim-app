package com.zaktech.grim

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.TextView
import android.view.Gravity
import android.graphics.Color
import android.view.View
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity

class FullscreenReminderActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle hide overlay action
        if (intent.action == "HIDE_OVERLAY") {
            finish()
            return
        }
        
        // Check if this is a navigation block overlay
        val isNavigationBlock = intent.getBooleanExtra("navigation_block", false)
        
        // Set up fullscreen behavior with modern flags
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            // Android 11+ (API 30+)
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(android.view.WindowInsets.Type.systemBars())
                controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Legacy Android versions
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            )
            
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
        }
        
        // If this is navigation block, show blocking screen
        if (isNavigationBlock) {
            showNavigationBlockScreen()
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Ensure immersive mode is maintained
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(android.view.WindowInsets.Type.systemBars())
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
        }
    }
    
    // Intercept back button
    override fun onBackPressed() {
        // Block back button when in navigation mode
        val isNavigationBlock = intent.getBooleanExtra("navigation_block", false)
        if (isNavigationBlock) {
            // Show a message or do nothing to block the back button
            return
        } else {
            super.onBackPressed()
        }
    }
    
    // Intercept other system keys
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        val isNavigationBlock = intent.getBooleanExtra("navigation_block", false)
        if (isNavigationBlock) {
            // Block volume keys, menu key, etc. when in navigation mode
            return when (keyCode) {
                KeyEvent.KEYCODE_BACK,
                KeyEvent.KEYCODE_HOME,
                KeyEvent.KEYCODE_APP_SWITCH,
                KeyEvent.KEYCODE_MENU,
                KeyEvent.KEYCODE_VOLUME_UP,
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_VOLUME_MUTE -> true
                else -> super.onKeyDown(keyCode, event)
            }
        }
        return super.onKeyDown(keyCode, event)
    }
    
    companion object {
        fun createIntent(context: Context, taskId: String, taskTitle: String): Intent {
            return Intent(context, FullscreenReminderActivity::class.java).apply {
                putExtra("task_id", taskId)
                putExtra("task_title", taskTitle)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            }
        }
    }
    
    private fun showNavigationBlockScreen() {
        // Create a simple blocking view
        val textView = TextView(this).apply {
            text = "🚫 NAVIGATION BLOCKED 🚫\n\nStay focused on your task!\n\nHome, Back, and Recent Apps buttons are disabled."
            setTextColor(Color.WHITE)
            textSize = 20f
            gravity = Gravity.CENTER
            setPadding(50, 50, 50, 50)
            setBackgroundColor(Color.BLACK)
        }
        
        setContentView(textView)
    }
}
