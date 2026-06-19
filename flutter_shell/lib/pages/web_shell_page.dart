import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'scanner_page.dart';

/// Hosts the bundled React/Vite warehouse app in a WebView and bridges scan
/// requests to the native [ScannerPage] via a JavaScript channel.
///
/// Wire contract — docs/flutter-scanner-migration/01-migration-spec.md §5:
///   Web  -> Flutter: ScannerChannel.postMessage(JSON { type, requestId, mode })
///   Flutter -> Web : window.dispatchEvent(CustomEvent 'warehouse-scan-result')
class WebShellPage extends StatefulWidget {
  const WebShellPage({super.key});

  @override
  State<WebShellPage> createState() => _WebShellPageState();
}

class _WebShellPageState extends State<WebShellPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ScannerChannel',
        onMessageReceived: _handleScannerRequest,
      )
      ..loadFlutterAsset('assets/wms-app/index.html');
  }

  Future<void> _handleScannerRequest(JavaScriptMessage message) async {
    if (!mounted) return;
    final Map<String, dynamic> request;
    try {
      request = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed payloads
    }
    if (request['type'] != 'scan') return;

    final requestId = '${request['requestId'] ?? ''}';
    final mode = '${request['mode'] ?? ''}';

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
    await _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WebViewWidget(controller: _controller));
  }
}
