// ---- Safe parsing helpers ----
//
// The backend may return numeric ids/quantities as int, double, or String
// (e.g. "100").  Web uses loose `Number()` coercion; these helpers mirror
// that so a type mismatch never throws and silently empties a record list.

String _toStr(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

/// API result wrapper matching Web's `{success, code, msg, data}` shape.
class WarehouseApiResult<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? code;

  const WarehouseApiResult({
    required this.success,
    this.message,
    this.data,
    this.code,
  });

  bool get isSuccess => success;
  bool get isFailure => !success;
}

/// Typed API error (can be thrown or returned in [WarehouseApiResult]).
class WarehouseApiError {
  final String message;
  final int? httpStatus;
  final String? serverCode;

  const WarehouseApiError({
    required this.message,
    this.httpStatus,
    this.serverCode,
  });

  @override
  String toString() =>
      'WarehouseApiError($message, httpStatus=$httpStatus, code=$serverCode)';
}

// ── Lookup / Query DTOs ──

/// Inventory item returned by scan-code lookup.
///
/// Maps to Web `src/api/outbound.js` `getItemByCode` response → `mapInventoryItem`.
class WarehouseItem {
  final int id;
  final String warehouse;
  final String itemName;
  final String code;
  final String spec;
  final int stockQty;
  final double costPrice;

  const WarehouseItem({
    required this.id,
    this.warehouse = '',
    this.itemName = '',
    this.code = '',
    this.spec = '',
    this.stockQty = 0,
    this.costPrice = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'warehouse': warehouse,
    'itemName': itemName,
    'code': code,
    'spec': spec,
    'stockQty': stockQty,
    'costPrice': costPrice,
  };

  factory WarehouseItem.fromJson(Map<String, dynamic> json) => WarehouseItem(
    id: json['id'] as int? ?? 0,
    warehouse: json['warehouse'] as String? ?? '',
    itemName: json['itemName'] as String? ?? '',
    code: json['code'] as String? ?? '',
    spec: json['spec'] as String? ?? '',
    stockQty: json['stockQty'] as int? ?? 0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Borrow record returned by scan-code lookup (return flow).
///
/// Maps to Web `src/api/return.js` `getBorrowersByQrcode` response → `mapBorrowerCandidate`.
class BorrowRecord {
  final int id;
  final int loanId;
  final int inventoryId;
  final String itemName;
  final String warehouse;
  final String code;
  final String spec;
  final int borrowQty;
  final double costPrice;
  final String borrower;
  final String borrowTime;

  const BorrowRecord({
    required this.id,
    required this.loanId,
    required this.inventoryId,
    this.itemName = '',
    this.warehouse = '',
    this.code = '',
    this.spec = '',
    this.borrowQty = 0,
    this.costPrice = 0.0,
    this.borrower = '',
    this.borrowTime = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'loanId': loanId,
    'inventoryId': inventoryId,
    'itemName': itemName,
    'warehouse': warehouse,
    'code': code,
    'spec': spec,
    'borrowQty': borrowQty,
    'costPrice': costPrice,
    'borrower': borrower,
    'borrowTime': borrowTime,
  };

  factory BorrowRecord.fromJson(Map<String, dynamic> json) => BorrowRecord(
    id: json['id'] as int? ?? 0,
    loanId: json['loanId'] as int? ?? 0,
    inventoryId: json['inventoryId'] as int? ?? 0,
    itemName: json['itemName'] as String? ?? '',
    warehouse: json['warehouse'] as String? ?? '',
    code: json['code'] as String? ?? '',
    spec: json['spec'] as String? ?? '',
    borrowQty: json['borrowQty'] as int? ?? 0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    borrower: json['borrower'] as String? ?? '',
    borrowTime: json['borrowTime'] as String? ?? '',
  );
}

/// Generic successful submission response from the server.
class BusinessSubmitResult {
  final bool success;
  final String? message;

  const BusinessSubmitResult({this.success = true, this.message});

  factory BusinessSubmitResult.fromJson(Map<String, dynamic> json) =>
      BusinessSubmitResult(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String?,
      );
}

// ── Record DTOs (Web parity) ──
//
// These mirror the normalized record objects produced by the Web mappers
// (src/api/outbound.js mapCheckoutRecord, return.js mapReturnRecord,
// inventory.js mapInventoryCheckRecord) so the Flutter record list and the
// record detail BottomSheet can show the same fields as the Web app.
//
// All fields default to safe empty values; missing backend data is rendered
// as "-" in the UI rather than fabricated.

/// One outbound (出库) record.
class CheckoutRecord {
  final int id;
  final int inventoryId;
  final String warehouse;
  final String itemName;
  final String code;
  final String spec;
  final int quantity;
  final int type; // 1 = 外销, 2 = 外借
  final double saleTotalPrice;
  final double saleUnitPrice;
  final double costPrice;
  final String remark;
  final String operatorName;
  final String time;
  final String status; // 正常 | 已撤销

  const CheckoutRecord({
    this.id = 0,
    this.inventoryId = 0,
    this.warehouse = '',
    this.itemName = '',
    this.code = '',
    this.spec = '',
    this.quantity = 0,
    this.type = 1,
    this.saleTotalPrice = 0.0,
    this.saleUnitPrice = 0.0,
    this.costPrice = 0.0,
    this.remark = '',
    this.operatorName = '',
    this.time = '',
    this.status = '正常',
  });

  /// "外销" when type == 1, otherwise "外借".
  String get method => type == 1 ? '外销' : '外借';

  factory CheckoutRecord.fromJson(Map<String, dynamic> raw) {
    final quantity = _toInt(raw['num']) ?? _toInt(raw['quantity']) ?? 0;
    final totalPrice = _toDouble(raw['totalPrice']);
    final costPrice = _toDouble(raw['costUnitPrice']) != 0.0
        ? _toDouble(raw['costUnitPrice'])
        : _toDouble(raw['costPrice']);
    // Web derives saleUnitPrice from outUnitPrice, falling back to totalPrice/num.
    final outUnit = _toDouble(raw['outUnitPrice']);
    final saleUnitPrice = outUnit != 0.0
        ? outUnit
        : (quantity > 0 ? totalPrice / quantity : 0.0);
    final outState = _toInt(raw['outState']) ?? 1;
    // numberAndSpec may carry "code/spec".
    final parts = _toStr(raw['numberAndSpec']).split('/');
    return CheckoutRecord(
      id: int.tryParse(_toStr(raw['id'])) ?? 0,
      inventoryId: int.tryParse(_toStr(raw['inventoryId'])) ?? 0,
      warehouse: _toStr(raw['storageName']),
      itemName: _toStr(raw['freightName']),
      code: _toStr(raw['freightNumber']).isNotEmpty
          ? _toStr(raw['freightNumber'])
          : (parts.isNotEmpty ? parts[0] : ''),
      spec: _toStr(raw['specification']).isNotEmpty
          ? _toStr(raw['specification'])
          : (parts.length > 1 ? parts[1] : ''),
      quantity: quantity,
      type: _toInt(raw['type']) ?? 1,
      saleTotalPrice: totalPrice,
      saleUnitPrice: saleUnitPrice,
      costPrice: costPrice,
      remark: _toStr(raw['outDescription']),
      operatorName: [
        _toStr(raw['operationNickName']),
        _toStr(raw['nickName']),
        _toStr(raw['operationUserName']),
      ].firstWhere((s) => s.isNotEmpty, orElse: () => ''),
      time: _toStr(raw['operationTime']),
      status: outState == 2 ? '已撤销' : '正常',
    );
  }
}

/// One return (归还) record.
class ReturnRecord {
  final int id;
  final String itemName;
  final String warehouse;
  final String code;
  final String spec;
  final int returnQty;
  final String borrower;
  final String operatorName;
  final String time;
  final String remark;
  final String status; // 正常 | 已撤销

  const ReturnRecord({
    this.id = 0,
    this.itemName = '',
    this.warehouse = '',
    this.code = '',
    this.spec = '',
    this.returnQty = 0,
    this.borrower = '',
    this.operatorName = '',
    this.time = '',
    this.remark = '',
    this.status = '正常',
  });

  factory ReturnRecord.fromJson(Map<String, dynamic> raw) {
    final parts = _toStr(raw['numberAndSpec']).split('/');
    final inState = _toInt(raw['inState']) ?? 1;
    return ReturnRecord(
      id: int.tryParse(_toStr(raw['id'])) ?? 0,
      itemName: _toStr(raw['freightName']),
      warehouse:
          _toStr(raw['warehouseName']).isNotEmpty
              ? _toStr(raw['warehouseName'])
              : _toStr(raw['storageName']),
      code: _toStr(raw['freightNumber']).isNotEmpty
          ? _toStr(raw['freightNumber'])
          : (parts.isNotEmpty ? parts[0] : ''),
      spec: _toStr(raw['specification']).isNotEmpty
          ? _toStr(raw['specification'])
          : (parts.length > 1 ? parts[1] : ''),
      returnQty: _toInt(raw['num']) ?? _toInt(raw['returnQty']) ?? 0,
      borrower: _toStr(raw['inBorrowerUserName']),
      operatorName: [
        _toStr(raw['operationNickName']),
        _toStr(raw['nickName']),
        _toStr(raw['operationUserName']),
        _toStr(raw['userName']),
      ].firstWhere((s) => s.isNotEmpty, orElse: () => ''),
      time: _toStr(raw['operationTime']),
      remark: _toStr(raw['inDescription']),
      status: inState == 2 ? '已撤销' : '正常',
    );
  }
}

/// One inventory-check (盘点) record.
class InventoryCheckRecord {
  final int id;
  final int inventoryId;
  final String itemName;
  final String warehouse;
  final String code;
  final String spec;
  final int bookQty;
  final int actualQty;
  final int difference;
  final double costPrice;
  final String remark;
  final String operatorName;
  final String time;
  final String status; // always 正常 per Web mapper

  const InventoryCheckRecord({
    this.id = 0,
    this.inventoryId = 0,
    this.itemName = '',
    this.warehouse = '',
    this.code = '',
    this.spec = '',
    this.bookQty = 0,
    this.actualQty = 0,
    this.difference = 0,
    this.costPrice = 0.0,
    this.remark = '',
    this.operatorName = '',
    this.time = '',
    this.status = '正常',
  });

  factory InventoryCheckRecord.fromJson(Map<String, dynamic> raw) {
    return InventoryCheckRecord(
      id: _toStr(raw['id']).isEmpty ? 0 : int.tryParse(_toStr(raw['id'])) ?? 0,
      inventoryId: int.tryParse(_toStr(raw['inventoryId'])) ?? 0,
      itemName: _toStr(raw['freightName']),
      warehouse: _toStr(raw['storageName']),
      code: _toStr(raw['freightNumber']),
      spec: _toStr(raw['specification']),
      bookQty: _toInt(raw['warehousNum']) ?? 0,
      actualQty: _toInt(raw['physicalInventoryQuantity']) ?? _toInt(raw['actualQty']) ?? 0,
      difference: _toInt(raw['difference']) ?? 0,
      costPrice: _toDouble(raw['unitPrice']),
      remark: _toStr(raw['remark']),
      operatorName: _toStr(raw['purchaseUserName']),
      time: _toStr(raw['purchaseTime']),
      status: '正常',
    );
  }
}

/// Auth session returned by the login API.
class AuthSession {
  final String username;
  final Map<String, dynamic> profile;
  final DateTime loggedAt;

  const AuthSession({
    required this.username,
    this.profile = const {},
    required this.loggedAt,
  });

  /// Human-friendly display name for the UI (mirrors Web's displayName
  /// logic: profile.nickName → profile.user.nickName → username).
  /// Never a server name — always derived from login data.
  String get displayName {
    final nick = profile['nickName']?.toString() ?? '';
    if (nick.isNotEmpty) return nick;
    final user = profile['user'];
    if (user is Map) {
      final uNick = user['nickName']?.toString() ?? '';
      if (uNick.isNotEmpty) return uNick;
    }
    return username;
  }
}
