package com.zaktech.grim

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    companion object {
        var instance: MainActivity? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppBlockerPlugin.registerWith(flutterEngine, applicationContext)
    }

    fun startLockTaskMode() {
        try {
            startLockTask()
            println("Lock Task Mode started")
        } catch (e: Exception) {
            println("Error starting Lock Task Mode: $e")
        }
    }

    fun stopLockTaskMode() {
        try {
            stopLockTask()
            println("Lock Task Mode stopped")
        } catch (e: Exception) {
            println("Error stopping Lock Task Mode: $e")
        }
    }
}
