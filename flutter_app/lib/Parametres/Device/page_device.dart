import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'device_info_service.dart';
import '../Parametres/settings_colors.dart';

class DevicePage extends StatefulWidget {
  final Map<String, dynamic> hardware;

  const DevicePage({super.key, required this.hardware});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  Map<String, String> _deviceInfo = const {};

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceInfoService.read();
    if (mounted) setState(() => _deviceInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
    final os = _value(widget.hardware['os']);
    final arch = _value(widget.hardware['arch']);
    final cpu = _value(widget.hardware['cpu_name']);
    final cores = _value(widget.hardware['cores']);
    final totalRam = _number(widget.hardware['total_ram_mb']);
    final ramLabel = totalRam == null
        ? '—'
        : '${(totalRam / 1024).toStringAsFixed(1)} GB';
    final gpu = widget.hardware['gpu'];
    final gpuName = gpu is Map ? _value(gpu['name']) : '';
    final gpuVendor = gpu is Map ? _value(gpu['vendor']) : '';
    final gpuVram = gpu is Map ? _number(gpu['vram_mb']) : null;
    final model = _deviceInfo['model']?.trim() ?? '';
    final manufacturer = _deviceInfo['manufacturer']?.trim() ?? '';
    final deviceName = [
      manufacturer,
      model,
    ].where((part) => part.isNotEmpty).join(' ');

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
                  child: Icon(Icons.devices_rounded, color: colors.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deviceControl,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.deviceOverview,
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _identityCard(
              colors: colors,
              title: deviceName.isNotEmpty
                  ? deviceName
                  : cpu.isNotEmpty
                  ? cpu
                  : l10n.deviceModelUnavailable,
              subtitle: [os, arch].where((part) => part.isNotEmpty).join(' • '),
              model: model,
              manufacturer: manufacturer,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(
                  context,
                  colors,
                  l10n.ramMb,
                  ramLabel,
                  Icons.memory_rounded,
                  totalRam == null ? '' : '$totalRam MB',
                ),
                _metricCard(
                  context,
                  colors,
                  l10n.cores,
                  cores.isEmpty ? '—' : cores,
                  Icons.developer_board_rounded,
                  l10n.cpu,
                ),
                _metricCard(
                  context,
                  colors,
                  l10n.gpu,
                  gpuName.isEmpty ? l10n.noGpuDetected : gpuName,
                  Icons.graphic_eq_rounded,
                  gpuVram == null ? gpuVendor : '${gpuVram} MB VRAM',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.deviceOverview,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 10),
            _detailsCard(colors, [
              _detail(l10n.deviceModel, model, Icons.devices_outlined),
              _detail(l10n.manufacturer, manufacturer, Icons.factory_outlined),
              if (_deviceInfo['android_version']?.isNotEmpty ?? false)
                _detail(
                  l10n.androidVersion,
                  _deviceInfo['android_version']!,
                  Icons.android_rounded,
                ),
              _detail(l10n.os, os, Icons.window_rounded),
              _detail(l10n.arch, arch, Icons.memory_outlined),
              _detail(l10n.cpu, cpu, Icons.developer_board_outlined),
              if (gpuName.isNotEmpty)
                _detail(
                  l10n.gpu,
                  [
                    gpuName,
                    gpuVendor,
                  ].where((part) => part.isNotEmpty).join(' • '),
                  Icons.graphic_eq_outlined,
                ),
              if (gpuVram != null)
                _detail(l10n.vramMb, '$gpuVram MB', Icons.sd_storage_outlined),
            ]),
          ],
        );
      },
    );
  }

  Widget _identityCard({
    required SettingsColors colors,
    required String title,
    required String subtitle,
    required String model,
    required String manufacturer,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: colors.isDark ? 0.26 : 0.14),
            colors.panel2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.devices_other_rounded,
              color: colors.accent,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle, style: TextStyle(color: colors.muted)),
                ],
              ],
            ),
          ),
          if (model.isNotEmpty || manufacturer.isNotEmpty)
            Icon(Icons.verified_outlined, color: colors.accent, size: 20),
        ],
      ),
    );
  }

  Widget _metricCard(
    BuildContext context,
    SettingsColors colors,
    String label,
    String value,
    IconData icon,
    String detail,
  ) {
    final width = (MediaQuery.sizeOf(context).width - 330)
        .clamp(180.0, 280.0)
        .toDouble();
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(SettingsColors colors, List<_DeviceDetail> details) {
    return Container(
      decoration: BoxDecoration(
        color: colors.panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(details[index].icon, size: 18, color: colors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      details[index].label,
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      details[index].value.isEmpty ? '—' : details[index].value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _DeviceDetail _detail(String label, String value, IconData icon) =>
      _DeviceDetail(label, value, icon);

  String _value(Object? value) => value?.toString().trim() ?? '';

  int? _number(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
}

class _DeviceDetail {
  final String label;
  final String value;
  final IconData icon;

  const _DeviceDetail(this.label, this.value, this.icon);
}
