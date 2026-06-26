import 'dart:io';

import 'package:flutter/services.dart';

/// Local HTTP server that serves the bundled web app and reverse-proxies
/// /store/* to the warehouse backend.
///
/// Why: the React app is built for same-origin serving (Vite dev proxy in dev,
/// nginx in browser production). Loaded from file:// in the WebView it can
/// neither reach a relative /store nor a cross-origin backend (CORS / mixed
/// content). Serving the app from this localhost server and proxying /store to
/// the backend restores the same-origin model inside the APK — the React code
/// keeps using relative /store exactly as in dev.
///
/// The backend URL is supplied at runtime by the React app via the
/// ScannerChannel 'setApiTarget' message (mirrors the dev /__proxy-target flow).
class LocalWebServer {
  static const String _assetBase = 'assets/wms-app';

  HttpServer? _server;
  String? _apiTarget; // e.g. http://175.178.165.153:8082
  int port = 0;

  bool get isRunning => _server != null;
  String get origin => 'http://localhost:$port';

  /// Backend origin to reverse-proxy /store to. Set from the React side.
  void setApiTarget(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
    _apiTarget = clean;
  }

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = _server!.port;
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path.startsWith('/store')) {
        await _proxy(request);
      } else {
        await _serveAsset(request, path);
      }
    } catch (e) {
      _send(request, 500, 'text/plain; charset=utf-8', 'local server error: $e');
    }
  }

  // ---- Static asset serving (SPA fallback to index.html) ----

  Future<void> _serveAsset(HttpRequest request, String path) async {
    final assetPath = (path == '/' || path.isEmpty)
        ? '$_assetBase/index.html'
        : '$_assetBase$path';
    try {
      final data = await rootBundle.load(assetPath);
      _sendBytes(
        request,
        200,
        _contentTypeFor(assetPath),
        data.buffer.asUint8List(),
      );
    } catch (_) {
      // SPA fallback: unknown non-store path → index.html (client-side routing).
      try {
        final data = await rootBundle.load('$_assetBase/index.html');
        _sendBytes(
          request,
          200,
          _contentTypeFor('index.html'),
          data.buffer.asUint8List(),
        );
      } catch (_) {
        _send(request, 404, 'text/plain; charset=utf-8', 'not found');
      }
    }
  }

  // ---- Reverse proxy /store/* → <apiTarget>/store/* ----

  Future<void> _proxy(HttpRequest request) async {
    final target = _apiTarget;
    if (target == null || target.isEmpty) {
      _send(
        request,
        503,
        'application/json; charset=utf-8',
        '{"code":"1","msg":"未配置服务器地址，请先在设置中添加服务器"}',
      );
      return;
    }

    final query = request.uri.query.isEmpty ? '' : '?${request.uri.query}';
    final uri = Uri.parse('$target${request.uri.path}$query');

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final upstream = await client.openUrl(request.method, uri);

      // Forward request headers (drop hop-by-hop, host, content-length).
      request.headers.forEach((name, values) {
        final lower = name.toLowerCase();
        if (_isHopByHop(lower) ||
            lower == 'host' ||
            lower == 'content-length') {
          return;
        }
        upstream.headers.set(name, values);
      });

      // Forward body.
      final body = await _readBytes(request);
      if (body.isNotEmpty) {
        upstream.contentLength = body.length;
        upstream.add(body);
      }

      final upstreamResponse = await upstream.close();

      // Copy response status + headers. Strip Set-Cookie Domain so the browser
      // stores the session cookie for localhost (then we re-send it upstream).
      request.response.statusCode = upstreamResponse.statusCode;
      final responseBytes = <int>[];
      upstreamResponse.headers.forEach((name, values) {
        final lower = name.toLowerCase();
        if (_isHopByHop(lower) ||
            lower == 'content-length' ||
            lower == 'transfer-encoding') {
          return;
        }
        if (lower == 'set-cookie') {
          for (final v in values) {
            request.response.headers.add(name, _stripCookieDomain(v));
          }
          return;
        }
        request.response.headers.set(name, values);
      });

      await for (final chunk in upstreamResponse) {
        responseBytes.addAll(chunk);
      }
      request.response.contentLength = responseBytes.length;
      request.response.add(responseBytes);
      await request.response.close();
    } catch (e) {
      _send(
        request,
        502,
        'application/json; charset=utf-8',
        '{"code":"1","msg":"无法连接服务器：$e"}',
      );
    } finally {
      client.close(force: true);
    }
  }

  // ---- helpers ----

  Future<List<int>> _readBytes(HttpRequest request) async {
    final out = <int>[];
    await for (final chunk in request) {
      out.addAll(chunk);
    }
    return out;
  }

  static const Set<String> _hopByHop = {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailers',
    'transfer-encoding',
    'upgrade',
  };

  static bool _isHopByHop(String lower) => _hopByHop.contains(lower);

  static String _stripCookieDomain(String setCookie) {
    return setCookie
        .split(';')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && !p.toLowerCase().startsWith('domain='))
        .join('; ');
  }

  static String _contentTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.html')) return 'text/html; charset=utf-8';
    if (lower.endsWith('.js')) return 'text/javascript; charset=utf-8';
    if (lower.endsWith('.css')) return 'text/css; charset=utf-8';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.json')) return 'application/json; charset=utf-8';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.woff2')) return 'font/woff2';
    return 'application/octet-stream';
  }

  static void _send(HttpRequest request, int status, String contentType, String body) {
    request.response.statusCode = status;
    request.response.headers.set('Content-Type', contentType);
    request.response.write(body);
    request.response.close();
  }

  static void _sendBytes(
    HttpRequest request,
    int status,
    String contentType,
    List<int> body,
  ) {
    request.response.statusCode = status;
    request.response.headers.set('Content-Type', contentType);
    request.response.contentLength = body.length;
    request.response.add(body);
    request.response.close();
  }
}
