import 'package:material_ui/material_ui.dart';

import 'extension_item.dart';

/// Demande la configuration d'un serveur MCP (commande/URL + token).
/// Retourne l'item avec config rempli, ou null si annulé.
Future<ExtensionItem?> askMcpConfig(
  BuildContext context,
  ExtensionItem item,
) async {
  final cmdCtrl = TextEditingController(text: item.config['command'] ?? '');
  final urlCtrl = TextEditingController(text: item.config['url'] ?? '');
  final tokenCtrl = TextEditingController(text: item.config['token'] ?? '');
  return showDialog<ExtensionItem>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Configurer ${item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Serveur local (stdio) : commande de lancement'),
          TextField(
            controller: cmdCtrl,
            decoration: const InputDecoration(
              labelText: 'Commande',
              hintText: 'npx -y @modelcontextprotocol/server-github',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          const Text('Ou serveur distant (HTTP) : URL'),
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL distante',
              hintText: 'https://api.githubcopilot.com/mcp/',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: tokenCtrl,
            decoration: const InputDecoration(
              labelText: 'Token (optionnel)',
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final cfg = {
              ...item.config,
              if (cmdCtrl.text.trim().isNotEmpty) 'command': cmdCtrl.text.trim(),
              if (urlCtrl.text.trim().isNotEmpty) 'url': urlCtrl.text.trim(),
              if (tokenCtrl.text.trim().isNotEmpty) 'token': tokenCtrl.text.trim(),
            };
            Navigator.of(ctx).pop(
              ExtensionItem(
                id: item.id,
                name: item.name,
                description: item.description,
                kind: item.kind,
                icon: item.icon,
                enabled: item.enabled,
                config: cfg,
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}