import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import 'warehouse_api_models.dart';

/// Contract for the warehouse management backend API.
///
/// Mirrors `src/api/outbound.js`, `src/api/return.js`, `src/api/inventory.js`,
/// and `src/api/auth.js`.
/// All methods return [WarehouseApiResult] for consistent error handling.
///
/// Implementations:
/// - [MockWarehouseApiClient] — fixture data, no network (testing)
/// - [HttpWarehouseApiClient] — real HTTP calls
abstract class WarehouseApiClient {
  // ── Scan Lookup ──

  /// Look up an inventory item by its barcode / QR code.
  ///
  /// Maps to Web `getItemByCode(code)` → `GET /inventory/list/outbound_qrcode/{code}`.
  Future<WarehouseApiResult<WarehouseItem>> findItemByCode(String code);

  /// Look up borrow records by QR code (return flow).
  ///
  /// Maps to Web `getBorrowersByQrcode(qrcode)` → `GET /inventory/loan/loan_borrower_qrcode/{qrcode}`.
  Future<WarehouseApiResult<List<BorrowRecord>>> findBorrowersByQrcode(String qrcode);

  /// Get detailed borrow record for a specific borrower.
  Future<WarehouseApiResult<BorrowRecord>> getBorrowerDetail(int inventoryId, int borrowerUserId);

  // ── Checkout (出库) ──

  /// Submit a checkout form.
  ///
  /// Maps to Web `submitCheckout(record)` → `POST /inventory/list/outbound`.
  Future<WarehouseApiResult<BusinessSubmitResult>> submitCheckout(CheckoutSubmitPayload payload);

  /// Fetch checkout records for the current user today.
  Future<WarehouseApiResult<List<CheckoutRecord>>> fetchCheckoutRecords();

  // ── Return (归还) ──

  /// Submit a return form.
  ///
  /// Maps to Web `submitReturn(record)` → `POST /inventory/loan/loanReturnInbound`.
  Future<WarehouseApiResult<BusinessSubmitResult>> submitReturn(ReturnSubmitPayload payload);

  /// Fetch return records (recent 100).
  Future<WarehouseApiResult<List<ReturnRecord>>> fetchReturnRecords();

  // ── Inventory Check (盘点) ──

  /// Submit an inventory check form.
  ///
  /// Maps to Web `submitInventoryCheck(record)` → `POST /calculate/calculate/mobilePhoneInventory`.
  Future<WarehouseApiResult<BusinessSubmitResult>> submitInventoryCheck(InventoryCheckSubmitPayload payload);

  /// Fetch inventory check records (recent 100).
  Future<WarehouseApiResult<List<InventoryCheckRecord>>> fetchInventoryCheckRecords();

  // ── Auth ──

  /// Login with username and password.
  ///
  /// Maps to Web `login(username, password)` → `POST /login`.
  /// Returns [AuthSession] on success.
  Future<WarehouseApiResult<AuthSession>> login(String username, String password);

  /// Logout the current session.
  ///
  /// Maps to Web `logout()` → `POST /logout`.
  Future<WarehouseApiResult<void>> logout();
}
