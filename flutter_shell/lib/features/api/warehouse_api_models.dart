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
  String toString() => 'WarehouseApiError($message, httpStatus=$httpStatus, code=$serverCode)';
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

  factory BusinessSubmitResult.fromJson(Map<String, dynamic> json) => BusinessSubmitResult(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String?,
      );
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
}
