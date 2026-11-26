package com.aura.aura_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Redémarre le Foreground Service après un reboot (optionnel).
 * Désactivé par défaut (l'utilisateur doit relancer AURA).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Optionnel : redémarrer le service si l'inférence était active
            // val isActive = ...
            // if (isActive) {
            //     val svc = Intent(context, AuraInferenceService::class.java)
            //     context.startForegroundService(svc)
            // }
        }
    }
}