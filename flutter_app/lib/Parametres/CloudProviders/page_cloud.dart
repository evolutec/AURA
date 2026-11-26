import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../Parametres/settings_colors.dart';
import 'cloud_provider.dart';
import 'cloud_provider_config_dialog.dart';
import 'cloud_provider_store.dart';

/// Page « Fournisseurs cloud » : liste, ajout, configuration et suppression
/// des fournisseurs (inspiré de RikkaHub `ProviderSetting`).
class CloudPage extends StatefulWidget {
  const CloudPage({super.key});

  @override
  State<CloudPage> createState() => _CloudPageState();
}

class _CloudPageState extends State<CloudPage> {
  final _store = CloudProviderStore();
  List<CloudProvider> _providers = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final providers = await _store.load();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _loaded = true;
    });
  }

  Future<void> _persist() => _store.save(_providers);

  void _showAddProviderModal() {
    final colors = SettingsColors.of(context);
    if (colors == null) return;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => CloudProviderConfigDialog(
        colors: colors,
        l10n: l10n,
        onSave: (provider) {
          setState(() => _providers.add(provider));
          _persist();
        },
      ),
    );
  }

  void _showConfigProviderModal(CloudProvider provider) {
    final colors = SettingsColors.of(context);
    if (colors == null) return;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => CloudProviderConfigDialog(
        colors: colors,
        l10n: l10n,
        initial: provider,
        onSave: (updated) {
          setState(() {
            final index = _providers.indexWhere((p) => p.id == updated.id);
            if (index >= 0) {
              _providers[index] = updated;
            } else {
              _providers.add(updated);
            }
          });
          _persist();
        },
      ),
    );
  }

  void _deleteProvider(CloudProvider provider) {
    setState(() => _providers.removeWhere((p) => p.id == provider.id));
    _persist();
  }

  void _toggleProvider(CloudProvider provider) {
    setState(() {
      final index = _providers.indexWhere((p) => p.id == provider.id);
      if (index >= 0) {
        _providers[index] = provider.copyWith(enabled: !provider.enabled);
      }
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context);

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 900 ? 32.0 : 20.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.cloud_rounded, color: colors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cloudProviders,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_providers.length} ${l10n.cloudProviders}',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showAddProviderModal,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addProvider),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ProviderList(
                providers: _providers,
                colors: colors,
                l10n: l10n,
                onConfigure: _showConfigProviderModal,
                onToggle: _toggleProvider,
                onDelete: _deleteProvider,
              ),
              const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _ProviderList extends StatelessWidget {
  final List<CloudProvider> providers;
  final SettingsColors colors;
  final AppLocalizations l10n;
  final void Function(CloudProvider provider) onConfigure;
  final void Function(CloudProvider provider) onToggle;
  final void Function(CloudProvider provider) onDelete;

  const _ProviderList({
    required this.providers,
    required this.colors,
    required this.l10n,
    required this.onConfigure,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.panel2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: colors.muted, size: 40),
            const SizedBox(height: 12),
            Text(
              l10n.noModelsInstalled,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: providers
          .map((p) => _ProviderCard(
            provider: p,
            colors: colors,
            l10n: l10n,
            onConfigure: onConfigure,
            onToggle: onToggle,
            onDelete: onDelete,
          ))
          .toList(),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final CloudProvider provider;
  final SettingsColors colors;
  final AppLocalizations l10n;
  final void Function(CloudProvider provider) onConfigure;
  final void Function(CloudProvider provider) onToggle;
  final void Function(CloudProvider provider) onDelete;

  const _ProviderCard({
    required this.provider,
    required this.colors,
    required this.l10n,
    required this.onConfigure,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.panel2,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            provider.enabled ? Icons.cloud : Icons.cloud_off,
            color: provider.enabled ? colors.accent : colors.white70,
          ),
          title: Text(
            provider.name,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            provider.baseUrl.isNotEmpty ? provider.baseUrl : l10n.notConnected,
            style: TextStyle(color: colors.muted, fontSize: 11),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  provider.enabled ? Icons.visibility : Icons.visibility_off,
                  color: colors.white70,
                  size: 20,
                ),
                tooltip: provider.enabled ? 'Désactiver' : 'Activer',
                onPressed: () => onToggle(provider),
              ),
              FilledButton.tonalIcon(
                onPressed: () => onConfigure(provider),
                icon: const Icon(Icons.settings, size: 16),
                label: Text(l10n.configureModel),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      colors.accent.withValues(alpha: colors.isDark ? 0.16 : 0.1),
                  foregroundColor: colors.accent,
                ),
              ),
              if (!provider.builtIn)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.muted, size: 20),
                  tooltip: 'Supprimer',
                  onPressed: () => onDelete(provider),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
