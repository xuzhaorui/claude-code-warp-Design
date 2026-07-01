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
    final quantity = (raw['num'] as num?)?.toInt() ?? (raw['quantity'] as num?)?.toInt() ?? 0;
    final totalPrice = (raw['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final costPrice = (raw['costUnitPrice'] as num?)?.toDouble() ?? (raw['costPrice'] as num?)?.toDouble() ?? 0.0;
    // Web derives saleUnitPrice from outUnitPrice, falling back to totalPrice/num.
    final saleUnitPrice = (raw['outUnitPrice'] as num?)?.toDouble() ??
        (quantity > 0 ? totalPrice / quantity : 0.0);
    final outState = (raw['outState'] as num?)?.toInt() ?? 1;
    // numberAndSpec may carry "code/spec".
    final parts = (raw['numberAndSpec'] as String?)?.split('/') ?? const [];
    return CheckoutRecord(
      id: raw['id'] as int? ?? 0,
      inventoryId: raw['inventoryId'] as int? ?? 0,
      warehouse: raw['storageName'] as String? ?? '',
      itemName: raw['freightName'] as String? ?? '',
      code: (raw['freightNumber'] as String?) ?? (parts.isNotEmpty ? parts[0] : ''),
      spec: (raw['specification'] as String?) ?? (parts.length > 1 ? parts[1] : ''),
      quantity: quantity,
      type: raw['type'] as int? ?? 1,
      saleTotalPrice: totalPrice,
      saleUnitPrice: saleUnitPrice,
      costPrice: costPrice,
      remark: raw['outDescription'] as String? ?? '',
      operatorName: raw['operationNickName'] as String? ??
          raw['nickName'] as String? ??
          raw['operationUserName'] as String? ??
          '',
      time: raw['operationTime'] as String? ?? '',
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
    final parts = (raw['numberAndSpec'] as String?)?.split('/') ?? const [];
    final inState = (raw['inState'] as num?)?.toInt() ?? 1;
    return ReturnRecord(
      id: raw['id'] as int? ?? 0,
      itemName: raw['freightName'] as String? ?? '',
      warehouse: (raw['warehouseName'] as String?) ?? (raw['storageName'] as String?) ?? '',
      code: (raw['freightNumber'] as String?) ?? (parts.isNotEmpty ? parts[0] : ''),
      spec: (raw['specification'] as String?) ?? (parts.length > 1 ? parts[1] : ''),
      returnQty: (raw['num'] as num?)?.toInt() ?? (raw['returnQty'] as num?)?.toInt() ?? 0,
      borrower: raw['inBorrowerUserName'] as String? ?? '',
      operatorName: raw['operationNickName'] as String? ??
          raw['nickName'] as String? ??
          raw['operationUserName'] as String? ??
          raw['userName'] as String? ??
          '',
      time: raw['operationTime'] as String? ?? '',
      remark: raw['inDescription'] as String? ?? '',
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
      id: raw['id'] as int? ?? 0,
      inventoryId: raw['inventoryId'] as int? ?? 0,
      itemName: raw['freightName'] as String? ?? '',
      warehouse: raw['storageName'] as String? ?? '',
      code: raw['freightNumber'] as String? ?? '',
      spec: raw['specification'] as String? ?? '',
      bookQty: (raw['warehousNum'] as num?)?.toInt() ?? 0,
      actualQty: (raw['physicalInventoryQuantity'] as num?)?.toInt() ??
          (raw['actualQty'] as num?)?.toInt() ?? 0,
      difference: (raw['difference'] as num?)?.toInt() ?? 0,
      costPrice: (raw['unitPrice'] as num?)?.toDouble() ?? 0.0,
      remark: raw['remark'] as String? ?? '',
      operatorName: raw['purchaseUserName'] as String? ?? '',
      time: raw['purchaseTime'] as String? ?? '',
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
}
