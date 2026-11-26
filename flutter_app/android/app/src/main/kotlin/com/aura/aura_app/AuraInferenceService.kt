package com.aura.aura_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground Service pour l'inférence AURA (llama.cpp, ONNX, LiteRT).
 *
 * Maintient le process vivant pendant l'inférence (chat, génération, RAG).
 * Affiche une notification persistante avec les statistiques (tok/s, RAM).
 *
 * Démarré via : context.startForegroundService(Intent(context, AuraInferenceService::class.java))
 * Arrêté via   : context.stopService(Intent(context, AuraInferenceService::class.java))
 */
class AuraInferenceService : Service() {

    companion object {
        const val CHANNEL_ID = "aura_inference"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.aura.action.START_INFERENCE"
        const val ACTION_STOP  = "com.aura.action.STOP_INFERENCE"
        const val EXTRA_MODEL = "model"
        const val EXTRA_PROMPT = "prompt"

        // Statistiques temps réel (mises à jour par le core natif)
        @Volatile var currentTokensPerSec: Double = 0.0
        @Volatile var currentRamMb: Long = 0
        @Volatile var isInferencing: Boolean = false
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val model = intent.getStringExtra(EXTRA_MODEL) ?: "unknown"
                isInferencing = true
                startForeground(NOTIFICATION_ID, buildNotification(model, "Ready"))
            }
            ACTION_STOP -> {
                isInferencing = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                startForeground(NOTIFICATION_ID, buildNotification("unknown", "Ready"))
            }
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AURA Inference",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "AURA inference service (local LLM)"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(model: String, status: String): Notification {
        val content = buildString {
            append("Model: $model\n")
            append("Status: $status\n")
            if (currentTokensPerSec > 0) {
                append("Speed: ${"%.1f".format(currentTokensPerSec)} tok/s\n")
            }
            if (currentRamMb > 0) {
                append("RAM: ${currentRamMb} MB")
            }
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AURA")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isInferencing = false
        super.onDestroy()
    }
}