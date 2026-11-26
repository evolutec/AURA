import Foundation
import Flutter
import AVFoundation
import Speech

/// Plugin pour le mode voix plein écran (full voice) sur iOS.
///
/// Utilise SFSpeechRecognizer (Apple Speech) pour ASR streaming natif,
/// avec support barge-in (interruption) et gestion du tour de parole.
///
/// Méthodes exposées :
///   - startVoiceMode : démarre l'écoute
///   - stopVoiceMode  : arrête l'écoute
///   - speak(text)    : TTS via AVSpeechSynthesizer
public class VoicePlugin: NSObject, FlutterPlugin {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var synthesizer = AVSpeechSynthesizer()
    private var isRecording = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "aura/voice", binaryMessenger: registrar.messenger())
        let instance = VoicePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "aura/voice/events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermission":
            requestSpeechPermission(result: result)

        case "startListening":
            startListening(result: result)

        case "stopListening":
            stopListening()
            result(nil)

        case "speak":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError.invalidArguments)
                return
            }
            let lang = args["lang"] as? String ?? "fr-FR"
            speak(text: text, lang: lang)
            result(nil)

        case "stopSpeaking":
            synthesizer.stopSpeaking(at: .immediate)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestSpeechPermission(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                result(status == .authorized)
            }
        }
    }

    private func startListening(result: @escaping FlutterResult) {
        if isRecording {
            result(false)
            return
        }

        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            result(false)
            return
        }

        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            result(false)
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            result(false)
            return
        }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            result(false)
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                self.eventSink?(["text": text, "is_final": isFinal])
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
            }
        }

        isRecording = true
        result(true)
    }

    private func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    private func speak(text: String, lang: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    private var eventSink: FlutterEventSink?
}

extension VoicePlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}