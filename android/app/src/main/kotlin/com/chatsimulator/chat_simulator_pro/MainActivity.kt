package com.chatsimulator.chat_simulator_pro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.chatsimulator.chat_simulator_pro/automation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(ChatSimulatorAccessibilityService.isEnabled())
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FAILED_TO_OPEN", e.message, null)
                    }
                }
                "simulateType" -> {
                    val text = call.argument<String>("text")
                    if (text != null) {
                        ChatSimulatorAccessibilityService.simulateType(text)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
