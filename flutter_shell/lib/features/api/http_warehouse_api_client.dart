// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import '../settings/server_config_store.dart';
import 'warehouse_api_client.dart';
import 'warehouse_api_models.dart';

/// Real HTTP implementation of [WarehouseApiClient].
///
/// Builds URLs from [ServerConfig] baseUrl (matching Web's `buildApiUrl`),
/// sends form-urlencoded POST bodies (matching Web's `buildFormBody`),
/// parses responses following Web's `parseJsonResponse` + `ensureAjaxSuccess`,
/// and manages JSESSIONID cookie from login for session-persistent requests.
///
/// The session cookie is persisted to [SharedPreferences] so a logged-in
/// session survives app restarts (task-042).  [http.Client] is injectable
/// for testing (use [FakeHttpClient]).
class HttpWarehouseApiClient implements WarehouseApiClient {
  static const _kSessionCookie = 'wms.sessionCookie';

  final ServerConfigStore _configStore;
  final http.Client _httpClient;

  /// Session cookie (e.g. `JSESSIONID=xxx`) set after successful login.
  /// Loaded from persistent storage on construction so a previous login
  /// is restored across app restarts.
  String? _sessionCookie;

  HttpWarehouseApiClient({
    required ServerConfigStore configStore,
    http.Client? httpClient,
    bool restoreSession = true,
  })  : _configStore = configStore,
        _httpClient = httpClient ?? http.Client() {
    // Restoring reads SharedPreferences, which requires an initialized
    // binding; pure unit tests pass restoreSession: false to skip this.
    if (restoreSession) {
      _restoreSessionCookie();
    }
  }

  /// Whether a persisted session cookie exists (i.e. a prior login likely
  /// happened).  Used by main.dart to decide whether to skip the login page
  /// on cold start.
  static Future<bool> hasSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_kSessionCookie);
    return cookie != null && cookie.isNotEmpty;
  }

  Future<void> _restoreSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString(_kSessionCookie);
    if (_sessionCookie != null) {
      debugPrint('[Debug_Auth] restored session cookie from storage');
    }
  }

  // ── URL building ──

  /// Builds the full request URL matching Web's `buildApiUrl(path)`.
  /// - If baseUrl has a path component (e.g. `http://host/wms`), uses that path as context.
  /// - If baseUrl has no path, uses `/store` as context.
  /// - Example: baseUrl=`http://host:8081/wms` → `http://host:8081/wms/login`
  /// - Example: baseUrl=`http://host:8080` → `http://host:8080/store/login`
  Future<String> _buildUrl(String path) async {
    final active = await _configStore.loadActiveServer();
    final raw = active?.normalizedBaseUrl ?? '';
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    if (raw.isEmpty) return '/store$normalizedPath';

    try {
      final uri = Uri.parse(raw);
      final hasContextPath = uri.path.isNotEmpty && uri.path != '/';
      if (hasContextPath) {
        // Web: parsed.origin + parsed.pathname + path
        return '${uri.origin}${uri.path}$normalizedPath';
      }
      // Web: base + '/store' + path
      final base = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
      return '$base/store$normalizedPath';
    } catch (_) {
      final base = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
      return '$base/store$normalizedPath';
    }
  }

  // ── Headers ──

  /// Common request headers. Includes session cookie if logged in.
  /// Always sends `X-Requested-With: XMLHttpRequest` as Web does.
  Map<String, String> _headers() {
    final h = <String, String>{
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (_sessionCookie != null) {
      h['Cookie'] = _sessionCookie!;
    }
    return h;
  }

  /// Extracts session cookie from response Set-Cookie header and persists it.
  void _saveCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    // Grab the first cookie (JSESSIONID=xxx) and ignore attributes
    final firstCookie = setCookie.split(';').first.trim();
    if (firstCookie.startsWith('JSESSIONID=') || firstCookie.startsWith('SESSION=')) {
      _sessionCookie = firstCookie;
      _persistSessionCookie(firstCookie);
    }
  }

  /// Clears stored session cookie (called on logout).
  void _clearCookies() {
    _sessionCookie = null;
    _removeSessionCookie();
  }

  Future<void> _persistSessionCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionCookie, cookie);
  }

  Future<void> _removeSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionCookie);
  }

  // ── Helpers ──

  /// Builds form-urlencoded body matching Web's `buildFormBody`.
  Map<String, String> _formBody(Map<String, dynamic> fields) {
    final map = <String, String>{};
    fields.forEach((key, value) {
      if (value != null && value != '') {
        map[key] = value.toString();
      }
    });
    return map;
  }

  /// Parses JSON response following Web's `parseJsonResponse` + `ensureAjaxSuccess`.
  Future<Map<String, dynamic>> _parseResponse(http.Response response) async {
    if (response.statusCode == 401) {
      throw WarehouseApiError(message: '未登录或会话已过期', httpStatus: 401);
    }
    if (response.statusCode == 403) {
      throw WarehouseApiError(message: '账号权限不足', httpStatus: 403);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WarehouseApiError(
        message: 'HTTP ${response.statusCode}',
        httpStatus: response.statusCode,
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html')) {
      throw WarehouseApiError(message: '服务器返回了HTML而不是JSON', httpStatus: response.statusCode);
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WarehouseApiError(message: 'JSON解析失败');
    }

    // Web ensureAjaxSuccess logic
    if (data['success'] == false || data['code'] == '1') {
      throw WarehouseApiError(
        message: data['msg'] as String? ?? data['message'] as String? ?? '操作失败',
        serverCode: data['code'] as String?,
      );
    }
    // Normalize `code` to int for comparison (Web uses String, server may use int).
    final code = int.tryParse('${data['code']}') ?? -1;
    if (code != -1 && code != 0 && code != 200) {
      throw WarehouseApiError(
        message: data['msg'] as String? ?? data['message'] as String? ?? '操作失败',
        serverCode: data['code'] as String?,
      );
    }
    return data;
  }

  /// Normalizes table rows matching Web's `normalizeTableRows`.
  List<dynamic> _normalizeRows(Map<String, dynamic> payload) {
    final data = payload['data'] ?? payload;
    if (data is Map && data['rows'] is List) return data['rows'] as List;
    if (payload['rows'] is List) return payload['rows'] as List;
    if (data is List) return data;
    return [];
  }

  /// GET request, returns parsed JSON.
  Future<Map<String, dynamic>> _get(String path) async {
    final urlValue = await _buildUrl(path);
    final parsed = Uri.parse(urlValue);
    final request = http.Request('GET', parsed);
    request.headers.addAll(_headers());
    request.followRedirects = false;
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    debugPrint('[Debug_HTTP] >>> GET $urlValue');
    debugPrint('[Debug_HTTP] <<< status=${response.statusCode} Location=${response.headers['location']}');
    return _parseResponse(response);
  }

  /// POST request with form body, returns parsed JSON.
  /// POST request with form body, returns parsed JSON.
  /// If [allowRedirect] is true, 302 responses are treated as success
  /// (Spring Security login redirect pattern) and parsed as JSON.
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> fields, {bool saveCookie = false, bool allowRedirect = false}) async {
    final urlValue = await _buildUrl(path);
    final parsed = Uri.parse(urlValue);
    
    final request = http.Request('POST', parsed);
    request.headers.addAll({
      ..._headers(),
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    });
    request.bodyFields = _formBody(fields);
    request.followRedirects = false;
    
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    
    if (saveCookie) _saveCookies(response);
    
    // Handle Spring Security 302 login redirect: success + session cookie
    if (allowRedirect && response.statusCode == 302) {
      final location = response.headers['location'] ?? '';
      if (response.headers['set-cookie'] != null && !location.contains('error')) {
        // Login succeeded: return empty data to signal success
        return <String, dynamic>{'success': true, 'code': '0', 'data': <String, dynamic>{}};
      }
    }
    
    return _parseResponse(response);
  }

  // ── Auth methods ──

  @override
  Future<WarehouseApiResult<AuthSession>> login(String username, String password) async {
    try {
      final respData = await _post('/login', {
        'username': username,
        'password': password,
        'rememberMe': 'true',
      }, saveCookie: true, allowRedirect: true);
      // parse response data with safe type conversion
      final rawValue = respData['data'] ?? respData;
      final raw = rawValue is Map
          ? rawValue.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final profile = raw['profile'] as Map<String, dynamic>? ?? {};
      final session = AuthSession(
        username: raw['loginName'] as String? ?? username,
        profile: profile,
        loggedAt: DateTime.now(),
      );
      return WarehouseApiResult(success: true, data: session);
    } on WarehouseApiError catch (e) {
      debugPrint('[Debug_Auth] login WarehouseApiError: code=${e.serverCode} message=${e.message} httpStatus=${e.httpStatus}');
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      debugPrint('[Debug_Auth] login unexpected: $e ${e.runtimeType}');
      return WarehouseApiResult(success: false, message: '登录请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<void>> logout() async {
    try {
      await _post('/logout', {}, saveCookie: true);
      _clearCookies();
      return const WarehouseApiResult(success: true);
    } on WarehouseApiError catch (e) {
      _clearCookies();
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      _clearCookies();
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  // ── API methods ──

  @override
  Future<WarehouseApiResult<WarehouseItem>> findItemByCode(String code) async {
    try {
      final data = await _get('/inventory/list/outbound_qrcode/${Uri.encodeComponent(code)}');
      final raw = (data['data'] ?? data) as Map<String, dynamic>?;
      if (raw == null || raw.isEmpty) {
        return const WarehouseApiResult(success: false, message: '未找到该编号对应的库存货物');
      }
      final item = WarehouseItem(
        id: raw['id'] as int? ?? 0,
        warehouse: raw['storageName'] as String? ?? '',
        itemName: raw['freightName'] as String? ?? '',
        code: raw['freightNumber'] as String? ?? '',
        spec: raw['specification'] as String? ?? '',
        stockQty: int.tryParse('${raw['quantity'] ?? 0}') ?? 0,
        costPrice: (raw['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );
      return WarehouseApiResult(success: true, data: item);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<List<BorrowRecord>>> findBorrowersByQrcode(String qrcode) async {
    try {
      final data = await _get('/inventory/loan/loan_borrower_qrcode/${Uri.encodeComponent(qrcode)}');
      final rows = _normalizeRows(data);
      final records = rows.map((r) => _mapBorrowRecord(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  BorrowRecord _mapBorrowRecord(Map<String, dynamic> raw) => BorrowRecord(
        id: raw['id'] as int? ?? 0,
        loanId: raw['id'] as int? ?? 0,
        inventoryId: raw['inventoryId'] as int? ?? 0,
        itemName: raw['freightName'] as String? ?? '',
        warehouse: raw['storageName'] as String? ?? '',
        code: raw['freightNumber'] as String? ?? '',
        spec: raw['specification'] as String? ?? '',
        borrowQty: (raw['loanQuantity'] as num?)?.toInt() ?? 0,
        costPrice: (raw['loanPrice'] as num?)?.toDouble() ?? 0.0,
        borrower: raw['userName'] as String? ?? '',
        borrowTime: raw['recentLoanInboundTime'] as String? ?? '',
      );

  @override
  Future<WarehouseApiResult<BorrowRecord>> getBorrowerDetail(int inventoryId, int borrowerUserId) async {
    try {
      final data = await _get('/inventory/loan/$inventoryId/$borrowerUserId');
      final raw = (data['data'] ?? data) as Map<String, dynamic>?;
      if (raw == null) {
        return const WarehouseApiResult(success: false, message: '未找到借用人详情');
      }
      return WarehouseApiResult(success: true, data: _mapBorrowRecord(raw));
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitCheckout(CheckoutSubmitPayload payload) async {
    try {
      final fields = <String, dynamic>{
        'inventoryId': payload.inventoryId,
        'num': payload.quantity,
        'type': payload.type,
      };
      if (payload.type == 1 && payload.totalPrice != null) fields['totalPrice'] = payload.totalPrice;
      if (payload.type == 1 && payload.costUnitPrice != null) fields['costUnitPrice'] = payload.costUnitPrice;
      if (payload.type == 2 && payload.outDescription != null && payload.outDescription!.isNotEmpty) {
        fields['outDescription'] = payload.outDescription;
      }
      await _post('/inventory/list/outbound', fields);
      return const WarehouseApiResult(success: true, data: BusinessSubmitResult(message: '出库成功'));
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<List<CheckoutRecord>>> fetchCheckoutRecords() async {
    try {
      final data = await _post('/inventory/outbound/getUserOutboundInDay', {});
      final rows = _normalizeRows(data);
      final records = rows.map((r) => CheckoutRecord.fromJson(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitReturn(ReturnSubmitPayload payload) async {
    try {
      final fields = <String, dynamic>{
        'loanId': payload.loanId,
        'num': payload.returnQty,
        'freightId': payload.freightId,
        'storageId': payload.storageId,
      };
      if (payload.remark.isNotEmpty) fields['remark'] = payload.remark;
      await _post('/inventory/loan/inbound', fields);
      return const WarehouseApiResult(success: true, data: BusinessSubmitResult(message: '归还成功'));
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<List<ReturnRecord>>> fetchReturnRecords() async {
    try {
      final data = await _post('/inventory/loan/getUserLoanInDay', {});
      final rows = _normalizeRows(data);
      final records = rows.map((r) => ReturnRecord.fromJson(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitInventoryCheck(InventoryCheckSubmitPayload payload) async {
    try {
      final fields = <String, dynamic>{
        'inventoryId': payload.inventoryId,
        'actualQty': payload.actualQty,
      };
      if (payload.remark.isNotEmpty) fields['remark'] = payload.remark;
      await _post('/inventory/checkOrder/saveCheck', fields);
      return const WarehouseApiResult(success: true, data: BusinessSubmitResult(message: '盘点提交成功'));
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  @override
  Future<WarehouseApiResult<List<InventoryCheckRecord>>> fetchInventoryCheckRecords() async {
    try {
      final data = await _post('/inventory/checkOrder/getUserCheckInDay', {});
      final rows = _normalizeRows(data);
      final records = rows.map((r) => InventoryCheckRecord.fromJson(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }
}
