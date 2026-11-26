import Foundation
import Flutter
import UIKit

/// Plugin Keychain pour stocker les clés API de façon sécurisée sur iOS.
///
/// Méthodes exposées :
///   - set(key, value)   : stocke une valeur
///   - get(key)          : récupère une valeur
///   - delete(key)       : supprime une valeur
///   - has(key)          : vérifie l'existence
public class KeychainPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "aura/keychain", binaryMessenger: registrar.messenger())
        let instance = KeychainPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "set":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String,
                  let value = args["value"] as? String else {
                result(FlutterError.invalidArguments)
                return
            }
            let success = KeychainHelper.set(key: key, value: value)
            result(success)

        case "get":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String else {
                result(FlutterError.invalidArguments)
                return
            }
            result(KeychainHelper.get(key: key))

        case "delete":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String else {
                result(FlutterError.invalidArguments)
                return
            }
            result(KeychainHelper.delete(key: key))

        case "has":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String else {
                result(FlutterError.invalidArguments)
                return
            }
            result(KeychainHelper.has(key: key))

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

/// Helper Keychain (CRUD sécurisé)
class KeychainHelper {
    private static let service = "com.aura.aura_app.keychain"

    static func set(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func has(key: String) -> Bool {
        return get(key: key) != nil
    }
}

extension FlutterError {
    static var invalidArguments: FlutterError {
        return FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil)
    }
}