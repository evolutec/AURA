import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'agent_profile.dart';
import '../Parametres/settings_colors.dart';

class AgentEditorDialog extends StatefulWidget {
  final AgentProfile initial;
  final SettingsColors colors;

  const AgentEditorDialog({
    super.key,
    required this.initial,
    required this.colors,
  });

  @override
  State<AgentEditorDialog> createState() => _AgentEditorDialogState();
}

class _AgentEditorDialogState extends State<AgentEditorDialog> {
  static const _avatars = {
    'assistant': Icons.smart_toy_outlined,
    'code': Icons.code,
    'review': Icons.fact_check_outlined,
    'science': Icons.science_outlined,
    'write': Icons.edit_note,
    'support': Icons.support_agent,
  };

  late final TextEditingController _nameController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _quickPromptsController;
  late String _avatar;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.name);
    _systemPromptController = TextEditingController(
      text: widget.initial.systemPrompt,
    );
    _quickPromptsController = TextEditingController(
      text: widget.initial.quickPrompts.join('\n'),
    );
    _avatar = widget.initial.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _systemPromptController.dispose();
    _quickPromptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: colors.panel,
      title: Text(l10n.editAgent, style: TextStyle(color: colors.text)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.agentName),
                style: TextStyle(color: colors.text),
              ),
              const SizedBox(height: 20),
              Text(l10n.avatar, style: TextStyle(color: colors.text)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _avatars.entries.map((entry) {
                  final selected = _avatar == entry.key;
                  return IconButton.filledTonal(
                    tooltip: l10n.avatar,
                    onPressed: () => setState(() => _avatar = entry.key),
                    style: IconButton.styleFrom(
                      backgroundColor: selected ? colors.accent : colors.panel2,
                      foregroundColor: selected ? Colors.white : colors.white70,
                    ),
                    icon: Icon(entry.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _systemPromptController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.systemPrompt,
                  alignLabelWithHint: true,
                ),
                style: TextStyle(color: colors.text),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quickPromptsController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.quickPrompts,
                  helperText: l10n.quickPromptsHint,
                  alignLabelWithHint: true,
                ),
                style: TextStyle(color: colors.text),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final prompts = _quickPromptsController.text
        .split('\n')
        .map((prompt) => prompt.trim())
        .where((prompt) => prompt.isNotEmpty)
        .toList();
    Navigator.pop(
      context,
      AgentProfile(
        id: widget.initial.id,
        name: name,
        avatar: _avatar,
        systemPrompt: _systemPromptController.text.trim(),
        quickPrompts: prompts,
      ),
    );
  }
}

IconData agentAvatarIcon(String avatar) => switch (avatar) {
  'code' => Icons.code,
  'review' => Icons.fact_check_outlined,
  'science' => Icons.science_outlined,
  'write' => Icons.edit_note,
  'support' => Icons.support_agent,
  _ => Icons.smart_toy_outlined,
};
