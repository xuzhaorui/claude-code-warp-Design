import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FakeHttpClient implements http.Client {
  final Map<String, http.Response> _responses;
  final List<String> _urls = [];
  bool _failMode = false;

  FakeHttpClient(Map<String, dynamic> jsonResponses)
      : _responses = jsonResponses.map((k, v) => MapEntry(k,
            v is Map && v.containsKey('_statusCode')
                ? http.Response(
                    v['_body'] as String? ?? jsonEncode(v),
                    v['_statusCode'] as int? ?? 200,
                    headers: (v['_headers'] as Map<String, String>?) ?? {'content-type': 'application/json'},
                  )
                : http.Response(jsonEncode(v), 200, headers: {'content-type': 'application/json'})));

  List<String> get requestedUrls => List.unmodifiable(_urls);
  void setNetworkError() => _failMode = true;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) => _match(url.toString());
  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => _match(url.toString());
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _match(request.url.toString()).then((r) {
        final bytes = utf8.encode(r.body);
        return http.StreamedResponse(Stream.value(bytes), r.statusCode, headers: r.headers);
      });

  Future<http.Response> _match(String url) async {
    _urls.add(url);
    if (_failMode) throw Exception('Simulated network error');
    for (final e in _responses.entries) {
      if (url.contains(e.key)) return e.value;
    }
    return http.Response(jsonEncode({'success': false, 'msg': 'Not found'}), 404,
        headers: {'content-type': 'application/json'});
  }

  @override
  void close() {}
  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) => _match(url.toString());
  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => _match(url.toString());
  @override
  Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => _match(url.toString());
  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => _match(url.toString());
  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) => _match(url.toString()).then((r) => r.body);
  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) => _match(url.toString()).then((r) => r.bodyBytes);
}
