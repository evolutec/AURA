import UIKit
import Social
import MobileCoreServices

/// Share Extension pour AURA
/// Permet de partager du texte, des images et des URLs vers AURA
/// depuis n'importe quelle app.
class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Valider le contenu partagé
        if let contentText = contentText {
            return !contentText.isEmpty
        }
        return false
    }

    override func didSelectPost() {
        // Récupérer le contenu partagé
        let shared = SharedContentHelper.getContent()

        // Sauvegarder dans le groupe App Groups (partagé avec l'app principale)
        let defaults = UserDefaults(suiteName: "group.com.aura.aura_app")
        defaults?.set(shared.type, forKey: "share_type")
        defaults?.set(shared.text, forKey: "share_text")
        defaults?.set(shared.imagePath, forKey: "share_image_path")
        defaults?.synchronize()

        // Ouvrir l'app AURA
        if let url = URL(string: "aura://share") {
            openURL(url)
        }

        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
}

/// Helper pour extraire le contenu partagé
class SharedContentHelper {
    static func getContent() -> (type: String, text: String?, imagePath: String?) {
        // Récupérer depuis l'extension context
        // En pratique, utiliser les attachments du SLComposeServiceViewController

        // Pour l'instant, retourner un placeholder
        return ("text", "Contenu partagé", nil)
    }
}