// Warehouse shell ↔ real ScannerPage wiring layer.
//
// Composes [WarehouseShellFormWiring] with the real [ScannerPage].
// When the user taps the scan card, a [Navigator.push<String>] opens
// ScannerPage.  After the push returns, the scanned code is looked up
// via [WarehouseApiClient.findItemByCode] (or findBorrowersByQrcode
// for the return tab).  On success, the corresponding business form
// sheet auto-opens.  On failure, the code is still displayed but no
// form is opened.

import 'package:flutter/material.dart';

import '../../pages/scanner_page.dart';
import '../../utils/permissions.dart';
import '../api/warehouse_api_client.dart';
import '../api/warehouse_api_models.dart';
import '../business_forms/business_form_sheets.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import '../scanner/mobile_scanner_adapter.dart';
import '../scanner/scanner_adapter.dart';
import 'warehouse_shell.dart';
import 'warehouse_shell_form_wiring.dart';

// ── Public widget ──

/// Wires [WarehouseShellFormWiring] to [ScannerPage] + [WarehouseApiClient].
///
/// Scan flow:
///   1. Tap scan card → [Navigator.push<String>(ScannerPage)]
///   2. ScannerPage returns code via Navigator.pop
///   3. Call [WarehouseApiClient.findItemByCode] (or findBorrowersByQrcode)
///   4. On success → open form with real item data
///   5. On failure → display code, no form open
class WarehouseShellScannerEntry extends StatefulWidget {
  const WarehouseShellScannerEntry({
    super.key,
    this.adapter,
    this.apiClient,
    this.activeUsername,
    this.profile,
    this.onScanResult,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
    this.onLogout,
    this.onSessionExpired,
    this.onServerChanged,
  });

  final ScannerAdapter? adapter;

  /// API client for scan lookup.  Inject [MockWarehouseApiClient] for tests,
  /// or [HttpWarehouseApiClient] for production.
  final WarehouseApiClient? apiClient;

  /// Display name of the currently logged-in user, surfaced in the shell's
  /// status row.  Passed through to [WarehouseShellMin].
  final String? activeUsername;

  /// Login profile containing `permissions` and `roles` arrays.
  /// Drives tab visibility (getAllowedTabs) and cost-price visibility
  /// (canViewCostPrice) — mirrors Web `src/utils/permissions.js`.
  final Map<String, dynamic>? profile;

  /// Fired when the API signals the session has expired (401/302) so the
  /// app shell can clear state and return to the login page.
  final VoidCallback? onSessionExpired;

  /// Fired when the user requests logout from the settings page.
  final VoidCallback? onLogout;

  /// Fired when the active server is switched inside the settings page.
  final VoidCallback? onServerChanged;

  final ValueChanged<String>? onScanResult;
  final ValueChanged<CheckoutSubmitPayload>? onCheckoutSubmit;
  final ValueChanged<ReturnSubmitPayload>? onReturnSubmit;
  final ValueChanged<InventoryCheckSubmitPayload>? onInventoryCheckSubmit;

  @override
  State<WarehouseShellScannerEntry> createState() =>
      _WarehouseShellScannerEntryState();
}

class _WarehouseShellScannerEntryState
    extends State<WarehouseShellScannerEntry> {
  WarehouseTab _activeTab = WarehouseTab.checkout;

  /// GlobalKey for the ScaffoldMessenger so we can show SnackBars from async
  /// scan-lookup callbacks regardless of the current build context.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Per-tab records populated after successful submit.
  final Map<WarehouseTab, List<RecordItem>> _records = {};

  /// Guards against double-trigger during async API lookup.
  bool _isSearching = false;

  /// Maps a WarehouseTab to its permission key (mirrors Web AppShell allTabs).
  String _tabKey(WarehouseTab tab) {
    switch (tab) {
      case WarehouseTab.checkout: return 'outbound';
      case WarehouseTab.returnForm: return 'return';
      case WarehouseTab.inventoryCheck: return 'inventory';
      case WarehouseTab.settings: return 'settings';
    }
  }

  /// Reverse of [_tabKey].
  WarehouseTab? _tabFromKey(String key) {
    switch (key) {
      case 'outbound': return WarehouseTab.checkout;
      case 'return': return WarehouseTab.returnForm;
      case 'inventory': return WarehouseTab.inventoryCheck;
      case 'settings': return WarehouseTab.settings;
      default: return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load the default tab's records on mount so the list is populated
    // immediately, not only after the first submit.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetchRecords(_activeTab),
    );
  }

  /// Called when the active business tab changes — refreshes that tab's
  /// records from the API so each tab shows real data on entry.
  void _onTabChanged(WarehouseTab tab) {
    _activeTab = tab;
    _fetchRecords(tab);
  }

  /// Returns true (and fires [onSessionExpired]) when an API result signals
  /// the session has expired.
  ///
  /// Detection is multi-layered (matching Web `parseJsonResponse`):
  /// - [WarehouseApiResult.isAuthExpired] flag (set by the HTTP client when
  ///   the server responds with 401, 3xx redirect to login, login-page HTML,
  ///   or JSON code 401 / auth-expiry message).
  /// - Fallback: message string contains '未登录' (belt-and-suspenders for
  ///   any path that constructs a result without setting the flag).
  bool _isSessionExpired(WarehouseApiResult? result) {
    if (result == null || result.isSuccess) return false;
    final expired = result.isAuthExpired ||
        (result.message ?? '').contains('未登录');
    if (expired) {
      widget.onSessionExpired?.call();
      return true;
    }
    return false;
  }

  /// Shows a transient error/info toast.  Replaces the old inline scan-error
  /// card — avoids the error leaking onto the wrong tab and is more prominent.
  void _showToast(String message) {
    _messengerKey.currentState?.hideCurrentSnackBar();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Permission-derived visibility (mirrors Web permissions.js).
    final allowedTabs = getAllowedTabs(widget.profile);
    final showCostPrice = canViewCostPrice(widget.profile);

    // If the current active tab is not allowed, pick the first allowed one.
    // This handles the case where a user without 出库 permission lands on
    // the checkout tab by default.
    final tabKey = _tabKey(_activeTab);
    if (!allowedTabs.contains(tabKey) && allowedTabs.isNotEmpty) {
      _activeTab = _tabFromKey(allowedTabs.first) ?? _activeTab;
    }

    return ScaffoldMessenger(
      key: _messengerKey,
      child: WarehouseShellFormWiring(
        records: _records[_activeTab] ?? [],
        activeUsername: widget.activeUsername,
        allowedTabs: allowedTabs,
        showCostPrice: showCostPrice,
        onCheckoutSubmit: widget.onCheckoutSubmit,
        onReturnSubmit: widget.onReturnSubmit,
        onInventoryCheckSubmit: widget.onInventoryCheckSubmit,
      onScanRequested: (tab) {
        _activeTab = tab;
        _openScanner(context, tab);
      },
      onTabChanged: _onTabChanged,
      onLogout: widget.onLogout,
      onSessionExpired: widget.onSessionExpired,
      onServerChanged: widget.onServerChanged,
      ),
    );
  }

  Future<void> _openScanner(BuildContext context, WarehouseTab tab) async {
    debugPrint('[ScannerFlow] open scanner tab=$tab');

    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (scannerContext) => ScannerPage(
          adapter: widget.adapter ?? RealMobileScannerAdapter(),
          onScanResult: (code) {
            debugPrint('[ScannerFlow] scanner result=$code');
            widget.onScanResult?.call(code);
            Navigator.of(scannerContext).pop(code);
          },
          onClose: () {
            debugPrint('[ScannerFlow] scanner close');
            Navigator.of(scannerContext).pop();
          },
        ),
      ),
    );

    debugPrint('[ScannerFlow] scanner returned code=$code tab=$tab');

    if (!context.mounted || code == null || code.isEmpty) return;

    // Look up the code via API.
    await _lookupCode(context, tab, code);
  }

  Future<void> _lookupCode(
    BuildContext context,
    WarehouseTab tab,
    String code,
  ) async {
    final api = widget.apiClient;
    if (api == null) {
      // No API client — fall back to fixture (original behaviour).
      debugPrint('[ScannerFlow] no apiClient, using fixture');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _openBusinessFormForTabWithFixtures(context, tab, code);
      });
      return;
    }

    if (_isSearching) return;
    setState(() => _isSearching = true);

    try {
      switch (tab) {
        case WarehouseTab.checkout:
          await _lookupCheckout(context, code);
        case WarehouseTab.returnForm:
          await _lookupReturn(context, code);
        case WarehouseTab.inventoryCheck:
          await _lookupInventory(context, code);
        case WarehouseTab.settings:
          break;
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchRecords(WarehouseTab tab) async {
    final api = widget.apiClient;
    if (api == null) return;

    List<RecordItem> items = [];
    switch (tab) {
      case WarehouseTab.checkout:
        final result = await api.fetchCheckoutRecords();
        if (_isSessionExpired(result)) return;
        if (result.isSuccess && result.data != null) {
          items = result.data!.map((r) {
            final total = r.saleTotalPrice > 0
                ? '¥${r.saleTotalPrice.toStringAsFixed(2)}'
                : '-';
            return RecordItem(
              title: r.itemName.isEmpty ? '出库 #${r.inventoryId}' : r.itemName,
              detail: '${r.quantity} 件 · 总价 $total · ${r.method}',
              status: r.status,
              kind: RecordKind.checkout,
              source: r,
            );
          }).toList();
        }
      case WarehouseTab.returnForm:
        final result = await api.fetchReturnRecords();
        if (_isSessionExpired(result)) return;
        if (result.isSuccess && result.data != null) {
          items = result.data!
              .map(
                (r) => RecordItem(
                  title: r.itemName.isEmpty ? '归还 #${r.id}' : r.itemName,
                  detail: '${r.returnQty} 件 · ${r.borrower}',
                  status: r.status,
                  kind: RecordKind.returnForm,
                  source: r,
                ),
              )
              .toList();
        }
      case WarehouseTab.inventoryCheck:
        final result = await api.fetchInventoryCheckRecords();
        if (_isSessionExpired(result)) return;
        if (result.isSuccess && result.data != null) {
          items = result.data!.map((r) {
            final diff = r.difference;
            final diffText = diff > 0 ? '+$diff' : '$diff';
            return RecordItem(
              title: r.itemName.isEmpty ? '盘点 #${r.inventoryId}' : r.itemName,
              detail: '实盘 ${r.actualQty} 件 · 差值 $diffText 件',
              status: r.status,
              kind: RecordKind.inventoryCheck,
              source: r,
            );
          }).toList();
        }
      case WarehouseTab.settings:
        return;
    }
    if (mounted) {
      setState(() => _records[tab] = items);
    }
  }

  VoidCallback _onSubmitSuccess(WarehouseTab tab) {
    return () => _fetchRecords(tab);
  }

  Future<void> _lookupCheckout(BuildContext context, String code) async {
    final result = await widget.apiClient!.findItemByCode(code);
    if (!mounted) return;
    if (_isSessionExpired(result)) return;

    if (!result.isSuccess || result.data == null) {
      _showToast(result.message ?? '未找到该物资');
      return;
    }

    final item = result.data!;
    final snapshot = CheckoutItemSnapshot(
      id: item.id,
      stockQty: item.stockQty,
      costPrice: item.costPrice,
      itemName: item.itemName,
      warehouse: item.warehouse,
      code: item.code,
      spec: item.spec,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showCheckoutFormSheet(
        context: context,
        item: snapshot,
        showCostPrice: canViewCostPrice(widget.profile),
        apiClient: widget.apiClient,
        onSubmitSuccess: _onSubmitSuccess(WarehouseTab.checkout),
        onSubmit: widget.onCheckoutSubmit,
      );
    });
  }

  Future<void> _lookupReturn(BuildContext context, String code) async {
    final result = await widget.apiClient!.findBorrowersByQrcode(code);
    if (!mounted) return;
    if (_isSessionExpired(result)) return;

    if (!result.isSuccess || result.data == null || result.data!.isEmpty) {
      _showToast(result.message ?? '未找到借用记录');
      return;
    }

    // Use the first borrow record.
    final record = result.data!.first;
    final snapshot = ReturnBorrowRecordSnapshot(
      loanId: record.loanId,
      freightId: record.freightId,
      storageId: record.storageId,
      borrowQty: record.borrowQty,
      costPrice: record.costPrice,
      itemName: record.itemName,
      borrower: record.borrower,
      warehouse: record.warehouse,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showReturnFormSheet(
        context: context,
        record: snapshot,
        showCostPrice: canViewCostPrice(widget.profile),
        apiClient: widget.apiClient,
        onSubmitSuccess: _onSubmitSuccess(WarehouseTab.returnForm),
        onSubmit: widget.onReturnSubmit,
      );
    });
  }

  Future<void> _lookupInventory(BuildContext context, String code) async {
    final result = await widget.apiClient!.findItemByCode(code);
    if (!mounted) return;
    if (_isSessionExpired(result)) return;

    if (!result.isSuccess || result.data == null) {
      _showToast(result.message ?? '未找到该物资');
      return;
    }

    final item = result.data!;
    final snapshot = InventoryCheckItemSnapshot(
      id: item.id,
      stockQty: item.stockQty,
      itemName: item.itemName,
      code: item.code,
      spec: item.spec,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showInventoryCheckFormSheet(
        context: context,
        item: snapshot,
        showCostPrice: canViewCostPrice(widget.profile),
        apiClient: widget.apiClient,
        onSubmitSuccess: _onSubmitSuccess(WarehouseTab.inventoryCheck),
        onSubmit: widget.onInventoryCheckSubmit,
      );
    });
  }

  /// Fallback: open form with fixture data (no API client set).
  void _openBusinessFormForTabWithFixtures(
    BuildContext context,
    WarehouseTab tab,
    String code,
  ) {
    debugPrint('[ScannerFlow] open $tab form (fixture) code=$code');
    switch (tab) {
      case WarehouseTab.checkout:
        showCheckoutFormSheet(
          context: context,
          item: _Fixture.checkoutItem,
          apiClient: widget.apiClient,
          onSubmitSuccess: _onSubmitSuccess(tab),
          onSubmit: widget.onCheckoutSubmit,
        );
      case WarehouseTab.returnForm:
        showReturnFormSheet(
          context: context,
          record: _Fixture.returnRecord,
          apiClient: widget.apiClient,
          onSubmitSuccess: _onSubmitSuccess(tab),
          onSubmit: widget.onReturnSubmit,
        );
      case WarehouseTab.inventoryCheck:
        showInventoryCheckFormSheet(
          context: context,
          item: _Fixture.inventoryItem,
          apiClient: widget.apiClient,
          onSubmitSuccess: _onSubmitSuccess(tab),
          onSubmit: widget.onInventoryCheckSubmit,
        );
      case WarehouseTab.settings:
        break;
    }
  }
}

// ── Fixture data (fallback when no apiClient) ──

class _Fixture {
  _Fixture._();

  static const checkoutItem = CheckoutItemSnapshot(
    id: 1001,
    stockQty: 50,
    costPrice: 25.0,
    itemName: 'Widget Pro',
    warehouse: '主仓库',
    code: 'WP-001',
    spec: '500ml',
  );

  static const returnRecord = ReturnBorrowRecordSnapshot(
    loanId: 201,
    freightId: 202,
    storageId: 203,
    borrowQty: 30,
    costPrice: 20.0,
    itemName: 'Borrowed Item',
    borrower: '张三',
    warehouse: '主仓库',
  );

  static const inventoryItem = InventoryCheckItemSnapshot(
    id: 3001,
    stockQty: 100,
    itemName: 'Stock Item A',
    code: 'SA-001',
    spec: '1L',
  );
}
