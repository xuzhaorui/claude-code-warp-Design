import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/local_web_server.dart';
import 'scanner_page.dart';

/// Hosts the bundled React/Vite warehouse app and bridges it to native features.
///
/// The app is served by [LocalWebServer] at `http://localhost:PORT/` (not
/// file://) so its relative /store API calls are same-origin and the local
/// server can reverse-proxy them to the configured backend (no CORS).
///
/// ScannerChannel wire contract (docs/flutter-scanner-migration/01 §5 + API proxy):
///   {type:'scan', requestId, mode}                 → open ScannerPage
///   {type:'setApiTarget', url}                     → set the /store proxy target
///   Flutter → Web: window.dispatchEvent('warehouse-scan-result', {detail})
class WebShellPage extends StatefulWidget {
  const WebShellPage({super.key});

  @override
  State<WebShellPage> createState() => _WebShellPageState();
}

class _WebShellPageState extends State<WebShellPage> {
  final LocalWebServer _server = LocalWebServer();
  WebViewController? _controller;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await _server.start();
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'ScannerChannel',
          onMessageReceived: _handleMessage,
        )
        ..loadRequest(Uri.parse(_server.origin));
      _controller = controller;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _initError = '$e');
      }
    }
  }

  Future<void> _handleMessage(JavaScriptMessage message) async {
    if (!mounted) return;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed payloads
    }
    switch (msg['type']) {
      case 'setApiTarget':
        _server.setApiTarget('${msg['url'] ?? ''}');
        return;
      case 'scan':
        await _handleScan(msg);
        return;
    }
  }

  Future<void> _handleScan(Map<String, dynamic> msg) async {
    if (!mounted) return;
    final requestId = '${msg['requestId'] ?? ''}';
    final mode = '${msg['mode'] ?? ''}';

    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute<ScanResult>(
        builder: (_) => ScannerPage(mode: mode),
      ),
    );

    final detail = <String, dynamic>{'requestId': requestId};
    if (result == null) {
      detail['ok'] = false;
      detail['errorCode'] = 'USER_CANCELLED';
      detail['message'] = '用户取消扫码';
    } else {
      detail['ok'] = true;
      detail['text'] = result.text;
      detail['format'] = result.format;
      detail['source'] = 'flutter-mobile-scanner';
    }

    // jsonEncode yields a valid JS object literal; embed it directly.
    final payload = jsonEncode(detail);
    final js =
        "window.dispatchEvent(new CustomEvent('warehouse-scan-result',{detail:$payload}));";
    await _controller?.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('本地服务启动失败: $_initError'))),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(body: WebViewWidget(controller: controller));
  }
}
