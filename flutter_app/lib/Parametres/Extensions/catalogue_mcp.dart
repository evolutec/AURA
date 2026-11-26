import 'package:material_ui/material_ui.dart';

import 'catalogue_data.dart';
import 'extension_item.dart';

/// Modale de catalogue d'extensions (MCP, outils, skills).
/// Même dimension que la modale des paramètres.
class CatalogueMcp extends StatefulWidget {
  final ExtensionKind kind;
  final String title;
  final List<CatalogEntry> entries;

  const CatalogueMcp({
    super.key,
    required this.kind,
    required this.title,
    required this.entries,
  });

  @override
  State<CatalogueMcp> createState() => _CatalogueMcpState();
}

class _CatalogueMcpState extends State<CatalogueMcp> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width =
        screenSize.width < 1200 ? screenSize.width * 0.94 : 1200.0;
    final height =
        screenSize.height < 900 ? screenSize.height * 0.92 : 900.0;
    final filtered = widget.entries
        .where((e) =>
            _query.isEmpty ||
            e.name.toLowerCase().contains(_query.toLowerCase()) ||
            e.description.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2B2D31)),
          ),
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2B2D31)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront,
                        size: 18, color: Color(0xFF9B7BFF)),
                    const SizedBox(width: 12),
                    Text(
                      'Catalogue — ${widget.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return Card(
                      color: const Color(0xFF2B2D31),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.extension,
                            color: Color(0xFF9B7BFF)),
                        title: Row(
                          children: [
                            Flexible(child: Text(e.name)),
                            if (e.stars.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B7BFF)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        size: 11, color: Color(0xFFFFC857)),
                                    const SizedBox(width: 2),
                                    Text(e.stars,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.description),
                            if (e.command.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                e.command,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF9B7BFF),
                                ),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: e.command.isNotEmpty,
                        trailing: FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(e.toItem(widget.kind)),
                          child: const Text('Ajouter'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}