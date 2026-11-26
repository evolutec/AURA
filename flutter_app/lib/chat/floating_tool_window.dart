import 'package:material_ui/material_ui.dart';

import '../Parametres/Parametres/settings_colors.dart';
import 'browser_view.dart';
import 'chat_message.dart';

/// Fenêtre d'outil flottante (terminal / sandbox / navigateur) détachée du dock.
///
/// Modes : normal (déplaçable + redimensionnable), maximisé (plein écran),
/// réduit (pillule). Le contenu reste monté (Offstage) pour préserver la WebView.
class FloatingToolWindow extends StatefulWidget {
  final ToolRun run;
  final SettingsColors colors;
  final VoidCallback onRedock;
  final VoidCallback onClose;

  const FloatingToolWindow({
    super.key,
    required this.run,
    required this.colors,
    required this.onRedock,
    required this.onClose,
  });

  @override
  State<FloatingToolWindow> createState() => _FloatingToolWindowState();
}

enum _WinMode { normal, maximized, minimized }

class _FloatingToolWindowState extends State<FloatingToolWindow> {
  _WinMode _mode = _WinMode.normal;
  Offset _offset = const Offset(120, 90);
  Size _size = const Size(760, 520);

  static const double _minW = 360;
  static const double _minH = 240;

  @override
  void didUpdateWidget(FloatingToolWindow old) {
    super.didUpdateWidget(old);
    if (old.run.sessionId != widget.run.sessionId) {
      _mode = _WinMode.normal;
      _offset = const Offset(120, 90);
      _size = const Size(760, 520);
    }
  }

  Color get _accent =>
      widget.run.ok ? const Color(0xFF3FB950) : const Color(0xFFF85149);

  Widget _content() {
    final run = widget.run;
    if (run.kind == 'browser' && run.url.isNotEmpty) {
      return BrowserView(
        key: ValueKey('float_${run.sessionId}'),
        url: run.url,
        sessionId: run.sessionId,
      );
    }
    return Container(
      color: Colors.black.withOpacity(0.25),
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: SelectableText(
          run.output.isEmpty ? '(aucune sortie)' : run.output,
          style: TextStyle(
            fontSize: 12,
            color: run.ok ? widget.colors.text : _accent,
            fontFamily: 'Consolas',
          ),
        ),
      ),
    );
  }

  Widget _titleBar(bool canDrag) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: canDrag ? (d) => setState(() => _offset += d.delta) : null,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          children: [
            Icon(
              widget.run.kind == 'browser'
                  ? Icons.public
                  : widget.run.kind == 'sandbox'
                      ? Icons.code
                      : Icons.terminal,
              size: 15,
              color: _accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.run.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
            ),
            _btn(Icons.remove, 'Réduire', () {
              setState(() => _mode = _WinMode.minimized);
            }),
            _btn(
              _mode == _WinMode.maximized
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              _mode == _WinMode.maximized ? 'Restaurer' : 'Maximiser',
              () => setState(() => _mode =
                  _mode == _WinMode.maximized ? _WinMode.normal : _WinMode.maximized),
            ),
            _btn(Icons.vertical_split, 'Rattacher au dock', () {
              widget.onRedock();
            }),
            _btn(Icons.close, 'Fermer', () => widget.onClose()),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 15, color: widget.colors.muted),
      onPressed: onTap,
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final c = widget.colors;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        double x;
        double y;
        double w;
        double h;
        if (_mode == _WinMode.maximized) {
          x = 8;
          y = 8;
          w = (maxW - 16).clamp(_minW, maxW);
          h = (maxH - 16).clamp(_minH, maxH);
        } else if (_mode == _WinMode.minimized) {
          x = 0;
          y = 0;
          w = _size.width.clamp(_minW, maxW);
          h = _size.height.clamp(_minH, maxH);
        } else {
          w = _size.width.clamp(_minW, maxW);
          h = _size.height.clamp(_minH, maxH);
          x = _offset.dx.clamp(0.0, (maxW - w).clamp(0.0, maxW));
          y = _offset.dy.clamp(0.0, (maxH - h).clamp(0.0, maxH));
        }

        return Stack(
          children: [
            // Cadre complet conservé monté ; masqué visuellement en mode réduit.
            Positioned(
              left: x,
              top: y,
              width: w,
              height: h,
              child: Offstage(
                offstage: _mode == _WinMode.minimized,
                child: _frame(c, resizable: _mode == _WinMode.normal),
              ),
            ),
            if (_mode == _WinMode.minimized)
              Positioned(
                right: 16,
                bottom: 16,
                child: _pill(c),
              ),
          ],
        );
      },
    );
  }

  Widget _pill(SettingsColors c) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _mode = _WinMode.normal),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.panel2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.run.kind == 'browser' ? Icons.public : Icons.terminal,
                size: 14,
                color: _accent,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  widget.run.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame(SettingsColors c, {bool resizable = false}) {
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withOpacity(0.6)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleBar(_mode == _WinMode.normal),
          Expanded(child: _content()),
          if (resizable) _resizeHandle(c),
        ],
      ),
    );
  }

  Widget _resizeHandle(SettingsColors c) {
    return Align(
      alignment: Alignment.bottomRight,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeDownRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => setState(
            () => _size = Size(
              (_size.width + d.delta.dx).clamp(_minW, 4000),
              (_size.height + d.delta.dy).clamp(_minH, 4000),
            ),
          ),
          child: Container(
            width: 20,
            height: 20,
            color: Colors.transparent,
            alignment: Alignment.bottomRight,
            child: Icon(Icons.open_in_full, size: 12, color: c.muted),
          ),
        ),
      ),
    );
  }
}