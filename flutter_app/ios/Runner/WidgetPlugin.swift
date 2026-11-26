import Foundation
import Flutter
import UIKit
import WidgetKit

/// Plugin pour mettre à jour les widgets WidgetKit avec les stats AURA.
///
/// Méthodes exposées :
///   - updateWidget(stats) : met à jour les widgets avec tok/s, RAM, etc.
public class WidgetPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "aura/widget", binaryMessenger: registrar.messenger())
        let instance = WidgetPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "update":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError.invalidArguments)
                return
            }
            updateWidgetWithStats(stats: args)
            result(nil)

        case "reload":
            WidgetCenter.shared.reloadAllTimelines()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func updateWidgetWithStats(stats: [String: Any]) {
        // Store stats in UserDefaults for WidgetKit to read
        let defaults = UserDefaults(suiteName: "group.com.aura.aura_app")
        defaults?.set(stats["tok_s"] ?? 0, forKey: "aura_tok_s")
        defaults?.set(stats["ram_mb"] ?? 0, forKey: "aura_ram_mb")
        defaults?.set(stats["model"] ?? "AURA", forKey: "aura_model")
        defaults?.set(stats["is_inferencing"] ?? false, forKey: "aura_is_inferencing")

        // Reload widgets
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}