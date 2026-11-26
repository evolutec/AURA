import 'package:material_ui/material_ui.dart';
import 'dart:io';
import 'dart:ui';

import '../l10n/app_localizations.dart';
import '../Parametres/Parametres/settings_colors.dart';

/// Zone de saisie des prompts (champ texte + barre d'outils + envoi).
class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final SettingsColors colors;
  final bool reasoningEnabled;
  final bool toolsEnabled;
  final bool toolsAvailable;
  final bool isGenerating;
  final VoidCallback onToggleReasoning;
  final VoidCallback onToggleTools;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onAttach;
  final List<String> attachments;
  final void Function(int index) onRemoveAttachment;
  final Widget selectorRow;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.reasoningEnabled,
    required this.toolsEnabled,
    required this.toolsAvailable,
    required this.isGenerating,
    required this.onToggleReasoning,
    required this.onToggleTools,
    required this.onSend,
    required this.onStop,
    required this.onAttach,
    required this.attachments,
    required this.onRemoveAttachment,
    required this.selectorRow,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: colors.panel,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, color: colors.muted),
                          tooltip: l.attach,
                          onPressed: onAttach,
                        ),
                        Expanded(
                          child: TextField(
                            focusNode: focusNode,
                            controller: controller,
                            minLines: 1,
                            maxLines: 5,
                            style: TextStyle(color: colors.text, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: l.placeholder,
                              hintStyle:
                                  TextStyle(color: colors.muted, fontSize: 14),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (attachments.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (var i = 0; i < attachments.length; i++)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      size: 13,
                                      color: colors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        attachments[i]
                                            .split(Platform.pathSeparator)
                                            .last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.accent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    InkWell(
                                      onTap: () => onRemoveAttachment(i),
                                      child: Icon(
                                        Icons.close,
                                        size: 13,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(child: selectorRow),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.psychology,
                            color: reasoningEnabled ? colors.accent : colors.muted,
                          ),
                          tooltip: l.reasoning,
                          onPressed: onToggleReasoning,
                        ),
                        if (toolsAvailable)
                          IconButton(
                            icon: Icon(
                              Icons.bolt,
                              color: toolsEnabled ? colors.accent : colors.muted,
                            ),
                            tooltip: 'Outils',
                            onPressed: onToggleTools,
                          ),
                        if (isGenerating)
                          FilledButton.icon(
                            onPressed: onStop,
                            icon: const Icon(Icons.stop, size: 18),
                            label: Text(l.stop),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: onSend,
                            icon: const Icon(Icons.send, size: 18),
                            label: Text(l.send),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.accent,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}