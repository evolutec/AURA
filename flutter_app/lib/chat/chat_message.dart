import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../Parametres/Parametres/settings_colors.dart';
import '../Parametres/Parametres/appearance.dart';

/// Une exécution d'outil (terminal, sandbox, etc.) à afficher dans la bulle.
class ToolRun {
  final String name;
  final String input;
  final String output;
  final bool ok;
  final String kind;
  final String sessionId;
  final bool pinned;
  final String url;

  ToolRun({
    required this.name,
    required this.input,
    required this.output,
    required this.ok,
    this.kind = 'other',
    this.sessionId = '',
    this.pinned = false,
    this.url = '',
  });
}

/// Modèle d'un message de conversation.
class ChatMessage {
  final bool isUser;
  final String text;
  final double? tokensPerSec;
  final List<ToolRun> toolRuns;

  ChatMessage({
    required this.isUser,
    required this.text,
    this.tokensPerSec,
    List<ToolRun>? toolRuns,
  }) : toolRuns = toolRuns ?? const [];
}

/// Bulle affichant un message (utilisateur ou modèle) avec actions.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? modelName;
  final SettingsColors colors;
  final VoidCallback onRegenerate;
  final void Function(ToolRun run)? onDetachTool;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.colors,
    required this.onRegenerate,
    this.modelName,
    this.onDetachTool,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final appearance =
        AppearanceScope.of(context) ?? const AppearanceSettings();
    final l = AppLocalizations.of(context)!;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? colors.accent.withOpacity(0.85)
              : colors.panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: (isUser ? colors.accent : Colors.black)
                  .withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? l.you : (modelName ?? l.model),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white70 : colors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : colors.text,
                fontFamily: isUser ? appearance.chatUserFont : appearance.chatModelFont,
              ),
            ),
            if (isUser) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.copy, size: 14, color: Colors.white70),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: message.text)),
                    tooltip: l.copy,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ],
            if (!isUser && message.toolRuns.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...message.toolRuns.map(
                (r) => _ToolRunCard(
                  run: r,
                  colors: colors,
                  onDetach: onDetachTool == null ? null : () => onDetachTool!(r),
                ),
              ),
            ],
            if (!isUser) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.tokensPerSec != null)
                    Text(
                      '${message.tokensPerSec!.toStringAsFixed(1)} tok/s',
                      style: TextStyle(fontSize: 13, color: colors.muted),
                    ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 14, color: colors.muted),
                    onPressed: onRegenerate,
                    tooltip: l.regenerate,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 14, color: colors.muted),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: message.text)),
                    tooltip: l.copy,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte affichant une exécution d'outil (commande/code + sortie).
class _ToolRunCard extends StatelessWidget {
  final ToolRun run;
  final SettingsColors colors;
  final VoidCallback? onDetach;

  const _ToolRunCard({required this.run, required this.colors, this.onDetach});

  @override
  Widget build(BuildContext context) {
    final accent = run.ok ? const Color(0xFF3FB950) : const Color(0xFFF85149);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  run.ok ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    run.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 13, color: colors.muted),
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: '${run.input}\n\n${run.output}'),
                  ),
                  tooltip: AppLocalizations.of(context)!.copy,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                ),
                if (onDetach != null)
                  IconButton(
                    icon: Icon(
                      Icons.open_in_new,
                      size: 13,
                      color: colors.muted,
                    ),
                    onPressed: onDetach,
                    tooltip: 'Détacher',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                  ),
              ],
            ),
          ),
          if (run.input.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: SelectableText(
                run.input,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.text,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: SelectableText(
                  run.output.isEmpty ? '(aucune sortie)' : run.output,
                  style: TextStyle(
                    fontSize: 15,
                    color: run.ok ? colors.text : accent,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}