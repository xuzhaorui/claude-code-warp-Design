// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

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
/// [http.Client] is injectable for testing (use [FakeHttpClient]).
class HttpWarehouseApiClient implements WarehouseApiClient {
  final ServerConfigStore _configStore;
  final http.Client _httpClient;

  /// Session cookie (e.g. `JSESSIONID=xxx`) set after successful login.
  String? _sessionCookie;

  HttpWarehouseApiClient({
    required ServerConfigStore configStore,
    http.Client? httpClient,
  })  : _configStore = configStore,
        _httpClient = httpClient ?? http.Client();

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
      final base = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
      final hasContextPath = uri.path.isNotEmpty && uri.path != '/';
      final contextPath = hasContextPath ? uri.path : '/store';
      return '$base$contextPath$normalizedPath';
    } catch (_) {
      return '$raw/store$normalizedPath';
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

  /// Extracts session cookie from response Set-Cookie header.
  void _saveCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    // Grab the first cookie (JSESSIONID=xxx) and ignore attributes
    final firstCookie = setCookie.split(';').first.trim();
    if (firstCookie.startsWith('JSESSIONID=') || firstCookie.startsWith('SESSION=')) {
      _sessionCookie = firstCookie;
    }
  }

  /// Clears stored session cookie (called on logout).
  void _clearCookies() {
    _sessionCookie = null;
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
    if (data['code'] != null && data['code'] != '0' && data['code'] != '200' && data['code'] != 200) {
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
    final url = await _buildUrl(path);
    final response = await _httpClient.get(
      Uri.parse(url),
      headers: _headers(),
    );
    return _parseResponse(response);
  }

  /// POST request with form body, returns parsed JSON.
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> fields, {bool saveCookie = false}) async {
    final url = await _buildUrl(path);
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: {
        ..._headers(),
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      },
      body: _formBody(fields),
    );
    if (saveCookie) _saveCookies(response);
    return _parseResponse(response);
  }

  // ── Auth methods ──

  @override
  Future<WarehouseApiResult<AuthSession>> login(String username, String password) async {
    try {
      final data = await _post('/login', {
        'username': username,
        'password': password,
        'rememberMe': 'true',
      }, saveCookie: true);
      final raw = (data['data'] ?? data) as Map<String, dynamic>?;
      final profile = raw?['profile'] as Map<String, dynamic>? ?? {};
      final session = AuthSession(
        username: raw?['loginName'] as String? ?? username,
        profile: profile,
        loggedAt: DateTime.now(),
      );
      return WarehouseApiResult(success: true, data: session);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
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
  Future<WarehouseApiResult<List<CheckoutSubmitPayload>>> fetchCheckoutRecords() async {
    try {
      final data = await _post('/inventory/outbound/getUserOutboundInDay', {});
      final rows = _normalizeRows(data);
      final records = rows.map((r) => _mapCheckoutRecord(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  CheckoutSubmitPayload _mapCheckoutRecord(Map<String, dynamic> raw) {
    final rawType = raw['type'] as int? ?? 1;
    return CheckoutSubmitPayload(
      inventoryId: raw['inventoryId'] as int? ?? 0,
      quantity: raw['num'] as int? ?? (raw['quantity'] as num?)?.toInt() ?? 0,
      type: rawType,
      totalPrice: (raw['totalPrice'] as num?)?.toDouble(),
      costUnitPrice: (raw['costUnitPrice'] as num?)?.toDouble(),
      outDescription: raw['outDescription'] as String?,
    );
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
  Future<WarehouseApiResult<List<ReturnSubmitPayload>>> fetchReturnRecords() async {
    try {
      final data = await _post('/inventory/loan/getUserLoanInDay', {});
      final rows = _normalizeRows(data);
      final records = rows.map((r) => _mapReturnRecord(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  ReturnSubmitPayload _mapReturnRecord(Map<String, dynamic> raw) => ReturnSubmitPayload(
        loanId: raw['loanId'] as int? ?? (raw['id'] as int? ?? 0),
        freightId: raw['freightId'] as int? ?? 0,
        storageId: raw['storageId'] as int? ?? 0,
        returnQty: raw['num'] as int? ?? (raw['returnQty'] as num?)?.toInt() ?? 0,
        remark: raw['remark'] as String? ?? '',
      );

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
  Future<WarehouseApiResult<List<InventoryCheckSubmitPayload>>> fetchInventoryCheckRecords() async {
    try {
      final data = await _post('/inventory/checkOrder/getUserCheckInDay', {});
      final rows = _normalizeRows(data);
      final records = rows.map((r) => _mapInventoryCheckRecord(r as Map<String, dynamic>)).toList();
      return WarehouseApiResult(success: true, data: records);
    } on WarehouseApiError catch (e) {
      return WarehouseApiResult(success: false, message: e.message);
    } catch (e) {
      return WarehouseApiResult(success: false, message: '网络请求失败');
    }
  }

  InventoryCheckSubmitPayload _mapInventoryCheckRecord(Map<String, dynamic> raw) => InventoryCheckSubmitPayload(
        inventoryId: raw['inventoryId'] as int? ?? 0,
        actualQty: raw['actualQty'] as int? ?? (raw['num'] as num?)?.toInt() ?? 0,
        remark: raw['remark'] as String? ?? '',
      );
}
