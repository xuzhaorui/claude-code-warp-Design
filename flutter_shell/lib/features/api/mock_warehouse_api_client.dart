import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import 'warehouse_api_client.dart';
import 'warehouse_api_models.dart';

/// Fixture-data implementation of [WarehouseApiClient].
///
/// No network access.  Returns preset items for known codes and
/// failure for unknown codes.  Supports injecting failure scenarios.
class MockWarehouseApiClient implements WarehouseApiClient {
  /// Pre-configured inventory items keyed by scanned code.
  final Map<String, WarehouseItem> _items;

  /// Pre-configured borrow records keyed by scanned code.
  final Map<String, List<BorrowRecord>> _borrowRecords;

  /// If true, all mutations return failure.
  bool _failMode = false;

  MockWarehouseApiClient({
    Map<String, WarehouseItem>? items,
    Map<String, List<BorrowRecord>>? borrowRecords,
  })  : _items = items ?? _defaultItems,
        _borrowRecords = borrowRecords ?? _defaultBorrowRecords;

  /// Enable or disable fail mode for testing error paths.
  void setFailMode(bool fail) => _failMode = fail;

  // ── Scan Lookup ──

  @override
  Future<WarehouseApiResult<WarehouseItem>> findItemByCode(String code) async {
    final item = _items[code];
    if (item == null) {
      return const WarehouseApiResult(
        success: false,
        message: '未找到该编号对应的库存货物',
      );
    }
    return WarehouseApiResult(success: true, data: item);
  }

  @override
  Future<WarehouseApiResult<List<BorrowRecord>>> findBorrowersByQrcode(String qrcode) async {
    final records = _borrowRecords[qrcode];
    if (records == null || records.isEmpty) {
      return const WarehouseApiResult(
        success: false,
        message: '未找到对应的借用记录',
      );
    }
    return WarehouseApiResult(success: true, data: records);
  }

  @override
  Future<WarehouseApiResult<BorrowRecord>> getBorrowerDetail(int inventoryId, int borrowerUserId) async {
    // Find the matching record in the pre-configured map.
    for (final records in _borrowRecords.values) {
      for (final r in records) {
        if (r.inventoryId == inventoryId && r.id == borrowerUserId) {
          return WarehouseApiResult(success: true, data: r);
        }
      }
    }
    return const WarehouseApiResult(success: false, message: '未找到借用人详情');
  }

  // ── Checkout ──

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitCheckout(CheckoutSubmitPayload payload) async {
    if (_failMode) {
      return const WarehouseApiResult(success: false, message: '出库提交失败');
    }
    return const WarehouseApiResult(success: true, data: BusinessSubmitResult(message: '出库成功'));
  }

  @override
  Future<WarehouseApiResult<List<CheckoutSubmitPayload>>> fetchCheckoutRecords() async {
    return const WarehouseApiResult(success: true, data: []);
  }

  // ── Return ──

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitReturn(ReturnSubmitPayload payload) async {
    if (_failMode) {
      return const WarehouseApiResult(success: false, message: '归还提交失败');
    }
    return const WarehouseApiResult(success: true, data: BusinessSubmitResult(message: '归还成功'));
  }

  @override
  Future<WarehouseApiResult<List<ReturnSubmitPayload>>> fetchReturnRecords() async {
    return const WarehouseApiResult(success: true, data: []);
  }

  // ── Inventory Check ──

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitInventoryCheck(InventoryCheckSubmitPayload payload) async {
    if (_failMode) {
      return const WarehouseApiResult(success: false, message: '盘点提交失败');
    }
    return const WarehouseApiResult(success: true, data: BusinessSubmitResult(message: '盘点成功'));
  }

  @override
  Future<WarehouseApiResult<List<InventoryCheckSubmitPayload>>> fetchInventoryCheckRecords() async {
    return const WarehouseApiResult(success: true, data: []);
  }

  // ── Auth ──

  @override
  Future<WarehouseApiResult<AuthSession>> login(String username, String password) async {
    if (_failMode) {
      return const WarehouseApiResult(success: false, message: '登录失败');
    }
    return WarehouseApiResult(
      success: true,
      data: AuthSession(username: username, loggedAt: DateTime.now()),
    );
  }

  @override
  Future<WarehouseApiResult<void>> logout() async {
    return const WarehouseApiResult(success: true);
  }

  // ── Default fixtures ──

  static const _defaultItems = {
    'P293': WarehouseItem(
      id: 1001,
      stockQty: 50,
      costPrice: 25.0,
      itemName: 'Widget Pro',
      warehouse: '主仓库',
      code: 'WP-001',
      spec: '500ml',
    ),
    'SKU-TEST-001': WarehouseItem(
      id: 1002,
      stockQty: 100,
      costPrice: 15.0,
      itemName: 'Test Sku',
      warehouse: '副仓库',
      code: 'SKU-TEST-001',
      spec: '1L',
    ),
  };

  static const _defaultBorrowRecords = {
    'P293': [
      BorrowRecord(
        id: 201,
        loanId: 201,
        inventoryId: 1001,
        borrowQty: 30,
        costPrice: 20.0,
        itemName: 'Widget Pro',
        borrower: '张三',
        warehouse: '主仓库',
      ),
    ],
  };
}
