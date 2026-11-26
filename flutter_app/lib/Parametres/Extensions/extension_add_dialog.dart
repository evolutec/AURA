import 'package:material_ui/material_ui.dart';

import 'extension_item.dart';

/// Composant séparé d'ajout d'une extension (skill, outil ou MCP).
class ExtensionAddDialog extends StatefulWidget {
  final ExtensionKind kind;

  const ExtensionAddDialog({super.key, required this.kind});

  @override
  State<ExtensionAddDialog> createState() => _ExtensionAddDialogState();
}

class _ExtensionAddDialogState extends State<ExtensionAddDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String get _kindLabel => switch (widget.kind) {
        ExtensionKind.skill => 'skill',
        ExtensionKind.tool => 'outil',
        ExtensionKind.mcp => 'serveur MCP',
      };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final item = ExtensionItem(
      id: '${widget.kind.key}_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      description: _descCtrl.text.trim(),
      kind: widget.kind,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter un $_kindLabel'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ajouter')),
      ],
    );
  }
}
