package com.zaktech.grim

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.TextView
import android.view.Gravity
import android.graphics.Color
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
        
        // Set up fullscreen behavior
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        )
        
        // Set up immersive mode
        window.decorView.systemUiVisibility = (
            android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
        
        // If this is navigation block, show blocking screen
        if (isNavigationBlock) {
            showNavigationBlockScreen()
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Ensure immersive mode is maintained
        window.decorView.systemUiVisibility = (
            android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
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
            text = "Navigation Blocked\nStay focused on your task!"
            setTextColor(Color.WHITE)
            textSize = 24f
            gravity = Gravity.CENTER
            setPadding(50, 50, 50, 50)
        }
        
        setContentView(textView)
    }
}
