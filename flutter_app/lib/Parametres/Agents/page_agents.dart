import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'agent_editor_dialog.dart';
import 'agent_profile.dart';
import '../Parametres/settings_colors.dart';

class AgentsPage extends StatelessWidget {
  final List<AgentProfile> agents;
  final Future<void> Function(List<AgentProfile>) onChanged;

  const AgentsPage({super.key, required this.agents, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.agents,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),
        ...agents.map(
          (agent) => Card(
            color: colors.panel2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colors.accent.withValues(alpha: 0.16),
                child: Icon(
                  agentAvatarIcon(agent.avatar),
                  color: colors.accent,
                ),
              ),
              title: Text(agent.name, style: TextStyle(color: colors.text)),
              subtitle: Text(
                agent.systemPrompt.isEmpty ? l10n.agent : agent.systemPrompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: l10n.editAgent,
                    onPressed: () => _edit(context, agent),
                    icon: Icon(Icons.edit_outlined, color: colors.white70),
                  ),
                  IconButton(
                    tooltip: l10n.deleteAgent,
                    onPressed: agents.length > 1
                        ? () => _delete(context, agent)
                        : null,
                    icon: Icon(
                      Icons.delete_outline,
                      color: agents.length > 1 ? colors.white70 : colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _edit(
            context,
            AgentProfile(
              id: 'agent_${DateTime.now().microsecondsSinceEpoch}',
              name: l10n.newAgent,
              avatar: 'assistant',
              systemPrompt: '',
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.newAgent),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, AgentProfile initial) async {
    final colors = SettingsColors.of(context)!;
    final result = await showDialog<AgentProfile>(
      context: context,
      builder: (_) => AgentEditorDialog(initial: initial, colors: colors),
    );
    if (result == null) return;
    final updated = [...agents];
    final index = updated.indexWhere((agent) => agent.id == result.id);
    if (index == -1) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    await onChanged(updated);
  }

  Future<void> _delete(BuildContext context, AgentProfile agent) async {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.panel,
        title: Text(l10n.deleteAgent, style: TextStyle(color: colors.text)),
        content: Text(
          l10n.deleteAgentConfirmation(agent.name),
          style: TextStyle(color: colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteAgent),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onChanged(agents.where((item) => item.id != agent.id).toList());
    }
  }
}
