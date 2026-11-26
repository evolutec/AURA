import 'package:material_ui/material_ui.dart';

/// Sidebar toggle button used within the Aura sidebar.
/// Shows expand/collapse arrow based on current state.
class SidebarToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final bool isDesktop;

  const SidebarToggle({
    super.key,
    required this.expanded,
    required this.onToggle,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final white70 = Colors.white70;
    return IconButton(
      icon: Icon(expanded ? Icons.chevron_left : Icons.chevron_right,
          size: 18, color: white70),
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
      onPressed: () => onToggle(),
    );
  }
}