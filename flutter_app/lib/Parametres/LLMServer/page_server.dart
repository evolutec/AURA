import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../Parametres/settings_colors.dart';

/// Page « Serveur LLM ».
class ServerPage extends StatelessWidget {
  final VoidCallback onStartServer;

  const ServerPage({super.key, required this.onStartServer});

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppLocalizations.of(context)!.llmServer,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.serverNotRunning,
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onStartServer,
          child: Text(AppLocalizations.of(context)!.startServer),
        ),
      ],
    );
  }
}
