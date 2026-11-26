import 'package:material_ui/material_ui.dart';
import '../l10n/app_localizations.dart';

/// Context menu shown when clicking the vertical dots (⋮) next to a chat in the sidebar.
/// Provides [rename] and [delete] action options.
class ChatContextMenu extends StatelessWidget {
  final String chatTitle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ChatContextMenu({
    super.key,
    required this.chatTitle,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      tooltip: '',
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 16, color: Color(0xFF7C5CFF)),
              const SizedBox(width: 8),
              Text(l10n.renameChat, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 16, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(l10n.deleteChat, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        if (value == 'rename') {
          onRename();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF12151C) : const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.white,
      position: PopupMenuPosition.over,
    );
  }
}
