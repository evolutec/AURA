import Foundation
import Flutter
import UIKit

/// Plugin pour recevoir du contenu partagé (Share Extension / App Intent).
///
/// Méthodes exposées :
///   - getSharedContent : retourne {type, text?, imageUrl?}
public class SharePlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SharePlugin()

        let methodChannel = FlutterMethodChannel(name: "aura/share", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: "aura/share/events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSharedContent":
            result(getSharedContentFromPasteboard())

        case "clearSharedContent":
            UIPasteboard.general.string = nil
            UIPasteboard.general.image = nil
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getSharedContentFromPasteboard() -> [String: Any]? {
        let pasteboard = UIPasteboard.general

        if let text = pasteboard.string, !text.isEmpty {
            return ["type": "text", "text": text]
        }

        if let image = pasteboard.image {
            if let data = image.jpegData(compressionQuality: 0.8) {
                let path = saveImageToTemp(data: data)
                return ["type": "image", "imagePath": path]
            }
        }

        if let url = pasteboard.url {
            return ["type": "url", "text": url.absoluteString]
        }

        return nil
    }

    private func saveImageToTemp(data: Data) -> String? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "aura_share_\(UUID().uuidString).jpg"
        let fileUrl = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileUrl)
            return fileUrl.path
        } catch {
            return nil
        }
    }

    func setEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
    }
}

extension SharePlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}