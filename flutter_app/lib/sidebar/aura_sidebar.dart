import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../Parametres/Parametres/settings_colors.dart';
import '../chat/chat_context_menu.dart';
import 'sidebar.dart';

/// Barre latérale d'historique des conversations.
class AuraSidebar extends StatelessWidget {
  final bool expanded;
  final bool isDesktop;
  final List<String> chatTitles;
  final int currentChat;
  final SettingsColors colors;
  final VoidCallback onToggle;
  final VoidCallback onNewChat;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStats;
  final ValueChanged<int> onSwitchChat;
  final ValueChanged<int> onRenameChat;
  final ValueChanged<int> onDeleteChat;

  const AuraSidebar({
    super.key,
    required this.expanded,
    required this.isDesktop,
    required this.chatTitles,
    required this.currentChat,
    required this.colors,
    required this.onToggle,
    required this.onNewChat,
    required this.onOpenSettings,
    required this.onOpenStats,
    required this.onSwitchChat,
    required this.onRenameChat,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 6),
          child: Row(
            children: [
              Image.asset('assets/logo.jpg', width: 40, height: 40),
              if (expanded) ...[
                const SizedBox(width: 12),
                Text(
                  l.aura,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ],
              const Spacer(),
              SidebarToggle(
                expanded: expanded,
                onToggle: onToggle,
                isDesktop: isDesktop,
              ),
            ],
          ),
        ),
        Divider(color: colors.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: expanded
              ? FilledButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    l.newChat,
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  color: colors.white70,
                  iconSize: 20,
                  onPressed: onNewChat,
                  tooltip: l.newChat,
                ),
        ),
        Divider(color: colors.border),
        if (expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l.history,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: chatTitles.length,
                    itemBuilder: (context, index) {
                      final selected = index == currentChat;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: selected ? colors.accent : colors.white70,
                            size: 18,
                          ),
                          title: Text(
                            chatTitles[index],
                            style: TextStyle(color: colors.text, fontSize: 13),
                          ),
                          selected: selected,
                          selectedTileColor: colors.panel2,
                          trailing: ChatContextMenu(
                            chatTitle: chatTitles[index],
                            onRename: () => onRenameChat(index),
                            onDelete: () => onDeleteChat(index),
                          ),
                          visualDensity: VisualDensity.compact,
                          onTap: () => onSwitchChat(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 6,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: expanded
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.user,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.online,
                            style: TextStyle(fontSize: 11, color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.bar_chart, size: 20, color: colors.white70),
                      onPressed: onOpenStats,
                      tooltip: l.statistics,
                    ),
                    IconButton(
                      icon: Icon(Icons.tune, size: 20, color: colors.white70),
                      onPressed: onOpenSettings,
                      tooltip: l.settings,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}