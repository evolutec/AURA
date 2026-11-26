package com.aura.aura_app

import android.app.Activity
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin Flutter pour contrôler le Foreground Service et obtenir les stats.
 *
 * Méthodes exposées :
 *   - startInference(model) : démarre le service
 *   - stopInference()       : arrête le service
 *   - getStats()            : {tok_s, ram_mb, is_running}
 */
class SystemInfoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var context: android.content.Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "aura/system_info")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startInference" -> {
                val model = call.argument<String>("model") ?: "unknown"
                val svc = Intent(context, AuraInferenceService::class.java).apply {
                    action = AuraInferenceService.ACTION_START
                    putExtra(AuraInferenceService.EXTRA_MODEL, model)
                }
                ContextCompat.startForegroundService(context!!, svc)
                result.success(null)
            }
            "stopInference" -> {
                val svc = Intent(context, AuraInferenceService::class.java).apply {
                    action = AuraInferenceService.ACTION_STOP
                }
                context!!.startService(svc)
                result.success(null)
            }
            "getStats" -> {
                val stats = hashMapOf<String, Any>(
                    "tok_s" to AuraInferenceService.currentTokensPerSec,
                    "ram_mb" to AuraInferenceService.currentRamMb,
                    "is_running" to AuraInferenceService.isInferencing
                )
                result.success(stats)
            }
            "getDeviceInfo" -> {
                val info = hashMapOf<String, Any>(
                    "model" to Build.MODEL,
                    "manufacturer" to Build.MANUFACTURER,
                    "android_version" to Build.VERSION.RELEASE,
                    "sdk_int" to Build.VERSION.SDK_INT,
                    "abi" to (Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown")
                )
                result.success(info)
            }
            else -> result.notImplemented()
        }
    }
}