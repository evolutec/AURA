import 'package:flutter/material.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

import '../logger.dart';
import 'browser_registry.dart';

class BrowserView extends StatefulWidget {
  final String url;
  final double? height;
  final String? sessionId;

  const BrowserView({super.key, required this.url, this.height, this.sessionId});

  @override
  State<BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends State<BrowserView> {
  late ChromiumWebViewController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = ChromiumWebViewController(initialUrl: widget.url);
    _controller.onUrlChanged = (u) {
      if (u.isNotEmpty && widget.sessionId != null) {
        BrowserRegistry.setUrl(widget.sessionId!, u);
      }
    };
    if (widget.sessionId != null) {
      BrowserRegistry.register(widget.sessionId!, _controller);
    }
    AppLogger.info('BrowserView init url=${widget.url} sid=${widget.sessionId}');
  }

  @override
  void didUpdateWidget(BrowserView old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _controller.loadRequest(widget.url);
    }
    if (old.sessionId != widget.sessionId) {
      if (old.sessionId != null) BrowserRegistry.unregister(old.sessionId!);
      if (widget.sessionId != null) {
        BrowserRegistry.register(widget.sessionId!, _controller);
      }
    }
  }

  @override
  void dispose() {
    if (widget.sessionId != null) BrowserRegistry.unregister(widget.sessionId!);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: widget.height,
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.center,
        child: Text(
          'Erreur: $_error',
          style: const TextStyle(fontSize: 11, color: Colors.redAccent),
        ),
      );
    }
    final child = ChromiumWebView(
      controller: _controller,
      initialUrl: widget.url,
      disposeController: false,
      onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      },
    );
    if (widget.height != null) {
      return SizedBox(height: widget.height, child: child);
    }
    return child;
  }
}