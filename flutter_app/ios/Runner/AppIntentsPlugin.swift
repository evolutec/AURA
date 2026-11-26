import Foundation
import Flutter
import AppIntents

/// App Intent pour exposer AURA aux Shortcuts Siri.
///
/// Permet de :
///   - Poser une question à AURA (Ask Intent)
///   - Générer du texte (Generate Intent)
///   - Résumer un texte (Summarize Intent)
public struct AskAuraIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask AURA"
    static var description = IntentDescription("Pose une question à AURA (LLM local ou cloud)")
    static var openAppWhenRun = true

    @Parameter(title: "Question", description: "La question à poser")
    var question: String

    @Parameter(title: "Model", description: "Modèle à utiliser (optionnel)")
    var model: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // Appel au core AURA (via shared container)
        let answer = AuraCore.shared.generate(prompt: question, model: model)
        return .result(value: answer, dialog: IntentDialog(stringLiteral: answer))
    }
}

public struct SummarizeAuraIntent: AppIntent {
    static var title: LocalizedStringResource = "Summarize with AURA"
    static var description = IntentDescription("Résume un texte avec AURA")
    static var openAppWhenRun = true

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let prompt = "Résume ce texte en 3 points:\n\n\(text)"
        let summary = AuraCore.shared.generate(prompt: prompt)
        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

/// App Shortcut Provider (expose les intents à Siri/Shortcuts)
public struct AuraShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskAuraIntent(),
            phrases: [
                "Pose une question avec \(.applicationName)",
                "Demande à \(.applicationName)"
            ],
            shortTitle: "Ask AURA",
            systemImageName: "bubble.left.and.bubble.right"
        )
        AppShortcut(
            intent: SummarizeAuraIntent(),
            phrases: [
                "Résume avec \(.applicationName)",
                "Synthétise avec \(.applicationName)"
            ],
            shortTitle: "Summarize",
            systemImageName: "text.alignleft"
        )
    }
}

/// Singleton pour accéder au core AURA depuis les App Intents
class AuraCore {
    static let shared = AuraCore()

    func generate(prompt: String, model: String? = nil) -> String {
        // Appel au core Rust via FFI (aura_core.a linké statiquement)
        // En production : appeler les fonctions C du core
        // Pour l'instant, retourner un placeholder
        return "[AURA] Réponse à: \(prompt)"
    }
}