package com.example.protega

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class BackgroundGestureService : AccessibilityService() {

    private var tapCount = 0
    private var lastTapTime = 0L
    private val timeWindow = 800L // 800ms

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("ProtegaGestureService", "Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used, but required to override
    }

    override fun onInterrupt() {
        Log.d("ProtegaGestureService", "Service Interrupted")
    }

    override fun onKeyEvent(event: KeyEvent?): Boolean {
        if (event == null) return super.onKeyEvent(event)

        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP && event.action == KeyEvent.ACTION_DOWN) {
            val currentTime = System.currentTimeMillis()

            if (currentTime - lastTapTime > timeWindow) {
                tapCount = 1 // Reset count if outside window
            } else {
                tapCount++
            }

            lastTapTime = currentTime

            if (tapCount >= 3) {
                tapCount = 0

                // Check if gesture mode is set to 'volume_key' before triggering
                val prefs = applicationContext.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE
                )
                val gestureMode = prefs.getString("flutter.sos_gesture_type", "disabled") ?: "disabled"

                if (gestureMode != "volume_key") {
                    Log.d("ProtegaGestureService", "Triple Volume Up detected but gesture mode is '$gestureMode' — ignoring.")
                    return super.onKeyEvent(event)
                }

                Log.d("ProtegaGestureService", "Triple Volume Up Detected! Triggering SOS.")
                triggerSOS()
                return true // Consume the event to prevent volume change during SOS trigger
            }
        }
        return super.onKeyEvent(event)
    }

    private fun triggerSOS() {
        // 1. Broadcast to SosBroadcastReceiver for instant background service trigger
        val broadcastIntent = Intent("com.example.protega.NATIVE_SOS_TRIGGER")
        broadcastIntent.setPackage(packageName)
        sendBroadcast(broadcastIntent)
        Log.d("ProtegaGestureService", "SOS broadcast sent to SosBroadcastReceiver")

        // 2. Launch Activity to wake screen and bring app to foreground
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.example.protega.TRIGGER_SOS"
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
    }
}
