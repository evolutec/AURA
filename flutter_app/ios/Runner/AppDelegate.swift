import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    KeychainPlugin.register(with: registrar(forPlugin: "KeychainPlugin")!)
    SharePlugin.register(with: registrar(forPlugin: "SharePlugin")!)
    WidgetPlugin.register(with: registrar(forPlugin: "WidgetPlugin")!)
    VoicePlugin.register(with: registrar(forPlugin: "VoicePlugin")!)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Handle share extension / universal links
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Handle aura:// deep links
    return true
  }
}