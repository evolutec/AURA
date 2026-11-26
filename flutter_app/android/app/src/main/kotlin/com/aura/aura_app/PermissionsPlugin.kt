package com.aura.aura_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Plugin Flutter pour gérer les permissions runtime Android.
 */
class PermissionsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var activity: android.app.Activity? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "aura/permissions")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private fun permissionFor(name: String): String? {
        return when (name) {
            "microphone" -> Manifest.permission.RECORD_AUDIO
            "camera"     -> Manifest.permission.CAMERA
            "notifications" -> if (Build.VERSION.SDK_INT >= 33) Manifest.permission.POST_NOTIFICATIONS else null
            "storage"    -> if (Build.VERSION.SDK_INT >= 33) Manifest.permission.READ_MEDIA_IMAGES else Manifest.permission.READ_EXTERNAL_STORAGE
            "location"   -> Manifest.permission.ACCESS_FINE_LOCATION
            "calendar"   -> Manifest.permission.READ_CALENDAR
            else -> null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "check" -> {
                val perm = permissionFor(call.argument<String>("permission") ?: return result.success(false))
                if (perm == null) return result.success(true)
                val granted = ContextCompat.checkSelfPermission(activity!!, perm) == PackageManager.PERMISSION_GRANTED
                result.success(granted)
            }
            "request" -> {
                val name = call.argument<String>("permission") ?: return result.success(false)
                val perm = permissionFor(name)
                if (perm == null) return result.success(true)

                val granted = ContextCompat.checkSelfPermission(activity!!, perm) == PackageManager.PERMISSION_GRANTED
                if (granted) return result.success(true)

                pendingResult = result
                androidx.core.app.ActivityCompat.requestPermissions(activity!!, arrayOf(perm), REQUEST_CODE)
            }
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
            return true
        }
        return false
    }

    companion object {
        const val REQUEST_CODE = 1001
    }
}