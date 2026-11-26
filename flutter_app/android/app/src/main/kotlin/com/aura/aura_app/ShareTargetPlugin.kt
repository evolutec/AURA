package com.aura.aura_app

import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin Flutter pour recevoir du contenu partagé depuis le menu Android.
 *
 * Gère les intents ACTION_SEND (texte, images).
 */
class ShareTargetPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activity: android.app.Activity? = null
    private var pendingIntent: Intent? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "aura/share_target")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "aura/share_target/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    fun setActivity(activity: android.app.Activity?, intent: Intent?) {
        this.activity = activity
        this.pendingIntent = intent
        if (intent != null && intent.action == Intent.ACTION_SEND) {
            processSharedIntent(intent)
        }
    }

    private fun processSharedIntent(intent: Intent) {
        val mimeType = intent.type
        val shared = hashMapOf<String, Any?>(
            "mime_type" to (mimeType ?: "text/plain")
        )
        when {
            intent.hasExtra(Intent.EXTRA_TEXT) -> {
                shared["text"] = intent.getStringExtra(Intent.EXTRA_TEXT)
            }
            intent.hasExtra(Intent.EXTRA_STREAM) -> {
                val uri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                shared["image_path"] = uri?.path
            }
        }
        eventSink?.success(shared)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSharedText" -> {
                result.success(pendingIntent?.getStringExtra(Intent.EXTRA_TEXT))
            }
            "getSharedImagePath" -> {
                val uri = pendingIntent?.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                result.success(uri?.path)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        pendingIntent?.let { if (it.action == Intent.ACTION_SEND) processSharedIntent(it) }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}