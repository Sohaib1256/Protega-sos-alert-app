package com.example.protega

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import id.flutter.flutter_background_service.FlutterBackgroundServicePlugin
import org.json.JSONObject

/**
 * Receives the NATIVE_SOS_TRIGGER broadcast from BackgroundGestureService
 * and pipes it directly to the Flutter background isolate via the plugin's
 * public servicePipe API — zero latency, no SharedPreferences, no Activity required.
 */
class SosBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SosBroadcastReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != "com.example.protega.NATIVE_SOS_TRIGGER") return

        Log.d(TAG, "SOS broadcast received — piping to background Dart isolate via servicePipe")

        try {
            val json = JSONObject()
            json.put("method", "nativeSosFired")

            FlutterBackgroundServicePlugin.servicePipe.invoke(json)
            Log.d(TAG, "servicePipe.invoke() succeeded")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to invoke servicePipe: ${e.message}", e)
        }
    }
}
