import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../Parametres/settings_colors.dart';
import 'cloud_provider.dart';

/// Formulaire d'enregistrement d'un fournisseur cloud.
///
/// Inspiré de RikkaHub `ProviderSetting` : nom, endpoint (baseUrl),
/// clé API, type d'authentification, modèles et en-têtes personnalisés.
class CloudProviderConfigDialog extends StatefulWidget {
  final SettingsColors colors;
  final AppLocalizations l10n;
  final CloudProvider? initial;
  final void Function(CloudProvider provider) onSave;

  const CloudProviderConfigDialog({
    super.key,
    required this.colors,
    required this.l10n,
    this.initial,
    required this.onSave,
  });

  @override
  State<CloudProviderConfigDialog> createState() =>
      _CloudProviderConfigDialogState();
}

class _CloudProviderConfigDialogState extends State<CloudProviderConfigDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelsController;
  CloudAuthType _authType = CloudAuthType.apiKey;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _baseUrlController = TextEditingController(text: initial?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: initial?.apiKey ?? '');
    _modelsController = TextEditingController(
      text: initial?.models.join(', ') ?? '',
    );
    _authType = initial?.authType ?? CloudAuthType.apiKey;
    _enabled = initial?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelsController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final provider = CloudProvider(
      id: widget.initial?.id ?? _newId(),
      name: name,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      authType: _authType,
      models: _modelsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      enabled: _enabled,
      builtIn: widget.initial?.builtIn ?? false,
    );
    widget.onSave(provider);
    Navigator.of(context).pop();
  }

  static String _newId() {
    final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt =
        (DateTime.now().microsecond * 1000 + DateTime.now().millisecond % 997)
            .toRadixString(36);
    return '$rand-$salt';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final l10n = widget.l10n;
    return Dialog(
      backgroundColor: colors.panel2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? l10n.addProvider : l10n.configureModel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.provider,
                  border: const OutlineInputBorder(),
                  hintText: 'OpenAI, Anthropic, My API, …',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: 'Base URL / Endpoint',
                  border: const OutlineInputBorder(),
                  hintText: 'https://api.example.com/v1',
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<CloudAuthType>(
                segments: const [
                  ButtonSegment(
                    value: CloudAuthType.apiKey,
                    label: Text('API Key'),
                    icon: Icon(Icons.key),
                  ),
                  ButtonSegment(
                    value: CloudAuthType.account,
                    label: Text('Compte'),
                    icon: Icon(Icons.account_circle),
                  ),
                ],
                selected: {_authType},
                onSelectionChanged: (s) => setState(() => _authType = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                enabled: _authType == CloudAuthType.apiKey,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  border: const OutlineInputBorder(),
                  hintText: 'sk-…',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modelsController,
                decoration: InputDecoration(
                  labelText: l10n.installedModels,
                  border: const OutlineInputBorder(),
                  hintText: 'gpt-4o, claude-3-5-sonnet, …',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: Text(
                  'Activé',
                  style: TextStyle(color: colors.text),
                ),
                activeThumbColor: colors.accent,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
