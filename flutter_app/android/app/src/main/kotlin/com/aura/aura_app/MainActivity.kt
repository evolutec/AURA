package com.aura.aura_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var systemInfoPlugin: SystemInfoPlugin? = null
    private var permissionsPlugin: PermissionsPlugin? = null
    private var shareTargetPlugin: ShareTargetPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        systemInfoPlugin = SystemInfoPlugin()
        permissionsPlugin = PermissionsPlugin()
        shareTargetPlugin = ShareTargetPlugin()

        flutterEngine.plugins.add(systemInfoPlugin!!)
        flutterEngine.plugins.add(permissionsPlugin!!)
        flutterEngine.plugins.add(shareTargetPlugin!!)

        shareTargetPlugin?.setActivity(this, intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        shareTargetPlugin?.setActivity(this, intent)
    }
}