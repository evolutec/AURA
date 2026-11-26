import 'package:material_ui/material_ui.dart';

import 'extension_item.dart';
import 'extension_store.dart';
import 'extension_add_dialog.dart';
import 'catalogue_data.dart';
import 'catalogue_mcp.dart';
import 'skill_downloader.dart';
import 'mcp_config_dialog.dart';

/// Page de gestion des extensions pour un type donné (skill, outil, MCP).
class PageExtensions extends StatefulWidget {
  final ExtensionKind kind;
  final String title;
  final IconData icon;

  const PageExtensions({
    super.key,
    required this.kind,
    required this.title,
    required this.icon,
  });

  @override
  State<PageExtensions> createState() => _PageExtensionsState();
}

class _PageExtensionsState extends State<PageExtensions> {
  List<ExtensionItem> _items = [];
  bool _loading = true;

  List<ExtensionItem> get _filtered =>
      _items.where((e) => e.kind == widget.kind).toList();

  List<CatalogEntry> get _catalog => switch (widget.kind) {
        ExtensionKind.mcp => kMcpCatalog,
        ExtensionKind.tool => kToolsCatalog,
        ExtensionKind.skill => kSkillsCatalog,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ExtensionStore.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _persist() => ExtensionStore.save(_items);

  Future<void> _add() async {
    final item = await showDialog<ExtensionItem>(
      context: context,
      builder: (_) => ExtensionAddDialog(kind: widget.kind),
    );
    if (item == null) return;
    setState(() => _items.add(item));
    await _persist();
  }

  Future<void> _remove(ExtensionItem item) async {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    await _persist();
  }

  Future<void> _openCatalogue() async {
    final item = await showDialog<ExtensionItem>(
      context: context,
      builder: (_) => CatalogueMcp(
        kind: widget.kind,
        title: widget.title,
        entries: _catalog,
      ),
    );
    if (item == null) return;
    if (_items.any((e) => e.id == item.id)) return;
    var toAdd = item;
    if (widget.kind == ExtensionKind.skill) {
      toAdd = await SkillDownloader.enrich(item);
    } else if (widget.kind == ExtensionKind.mcp) {
      final configured = await askMcpConfig(context, item);
      if (configured == null) return;
      toAdd = configured;
    }
    setState(() => _items.add(toAdd));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _loading ? null : _openCatalogue,
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Catalogue'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _add,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Aucun élément installé.'),
            )
          else
            ...items.map((e) => _ExtensionTile(
                  item: e,
                  onToggle: (v) {
                    setState(() => e.enabled = v);
                    _persist();
                  },
                  onRemove: widget.kind == ExtensionKind.tool
                      ? null
                      : () => _remove(e),
                )),
        ],
      ),
    );
  }
}

class _ExtensionTile extends StatelessWidget {
  final ExtensionItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onRemove;

  const _ExtensionTile({
    required this.item,
    required this.onToggle,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.extension),
        title: Text(item.name),
        subtitle: Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: item.enabled, onChanged: onToggle),
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer',
              ),
          ],
        ),
      ),
    );
  }
}
