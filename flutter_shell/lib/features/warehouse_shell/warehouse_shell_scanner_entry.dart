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
import '../api/warehouse_api_client.dart';
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
    this.activeServerName,
    this.onScanResult,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
    this.onLogout,
  });

  final ScannerAdapter? adapter;

  /// API client for scan lookup.  Inject [MockWarehouseApiClient] for tests,
  /// or [HttpWarehouseApiClient] for production.
  final WarehouseApiClient? apiClient;

  /// Display name of the currently active server, surfaced in the shell's
  /// status row.  Passed through to [WarehouseShellMin].
  final String? activeServerName;

  /// Fired when the user requests logout from the settings page.
  final VoidCallback? onLogout;

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
  String? _scanError;
  WarehouseTab _activeTab = WarehouseTab.checkout;

  /// Per-tab records populated after successful submit.
  final Map<WarehouseTab, List<RecordItem>> _records = {};

  /// Guards against double-trigger during async API lookup.
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Load the default tab's records on mount so the list is populated
    // immediately, not only after the first submit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecords(_activeTab));
  }

  /// Called when the active business tab changes — refreshes that tab's
  /// records from the API so each tab shows real data on entry.
  void _onTabChanged(WarehouseTab tab) {
    _activeTab = tab;
    _fetchRecords(tab);
  }

  @override
  Widget build(BuildContext context) {
    // task-041: the user-visible Debug manual-code overlay is removed from
    // the production UI.  Real paper-label scanning remains the only
    // user-facing entry; the manual-input affordance is no longer rendered.
    return WarehouseShellFormWiring(
      scanError: _scanError,
      records: _records[_activeTab] ?? [],
      activeServerName: widget.activeServerName,
      onCheckoutSubmit: widget.onCheckoutSubmit,
      onReturnSubmit: widget.onReturnSubmit,
      onInventoryCheckSubmit: widget.onInventoryCheckSubmit,
      onScanRequested: (tab) {
        _activeTab = tab;
        _openScanner(context, tab);
      },
      onTabChanged: _onTabChanged,
      onLogout: widget.onLogout,
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

    setState(() {
      _scanError = null;
    });

    // Look up the code via API.
    await _lookupCode(context, tab, code);
  }

  Future<void> _lookupCode(BuildContext context, WarehouseTab tab, String code) async {
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
        if (result.isSuccess && result.data != null) {
          items = result.data!.map((r) => RecordItem(
            title: r.itemName.isEmpty ? '出库 #${r.inventoryId}' : r.itemName,
            detail: '${r.quantity} 件 · 成本 ¥${r.costPrice.toStringAsFixed(2)} · ${r.method}',
            status: r.status,
            kind: RecordKind.checkout,
            source: r,
          )).toList();
        }
      case WarehouseTab.returnForm:
        final result = await api.fetchReturnRecords();
        if (result.isSuccess && result.data != null) {
          items = result.data!.map((r) => RecordItem(
            title: r.itemName.isEmpty ? '归还 #${r.id}' : r.itemName,
            detail: '${r.returnQty} 件 · ${r.borrower}',
            status: r.status,
            kind: RecordKind.returnForm,
            source: r,
          )).toList();
        }
      case WarehouseTab.inventoryCheck:
        final result = await api.fetchInventoryCheckRecords();
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

    if (!result.isSuccess || result.data == null) {
      setState(() => _scanError = result.message ?? '未找到该物资');
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
          apiClient: widget.apiClient,
          onSubmitSuccess: _onSubmitSuccess(WarehouseTab.checkout),
          onSubmit: widget.onCheckoutSubmit,
      );
    });
  }

  Future<void> _lookupReturn(BuildContext context, String code) async {
    final result = await widget.apiClient!.findBorrowersByQrcode(code);
    if (!mounted) return;

    if (!result.isSuccess || result.data == null || result.data!.isEmpty) {
      setState(() => _scanError = result.message ?? '未找到借用记录');
      return;
    }

    // Use the first borrow record.
    final record = result.data!.first;
    final snapshot = ReturnBorrowRecordSnapshot(
      loanId: record.loanId,
      freightId: record.id,
      storageId: record.inventoryId,
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
        apiClient: widget.apiClient,
        onSubmitSuccess: _onSubmitSuccess(WarehouseTab.returnForm),
        onSubmit: widget.onReturnSubmit,
      );
    });
  }

  Future<void> _lookupInventory(BuildContext context, String code) async {
    final result = await widget.apiClient!.findItemByCode(code);
    if (!mounted) return;

    if (!result.isSuccess || result.data == null) {
      setState(() => _scanError = result.message ?? '未找到该物资');
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
        apiClient: widget.apiClient,
        onSubmitSuccess: _onSubmitSuccess(WarehouseTab.inventoryCheck),
        onSubmit: widget.onInventoryCheckSubmit,
      );
    });
  }

  /// Fallback: open form with fixture data (no API client set).
  void _openBusinessFormForTabWithFixtures(
      BuildContext context, WarehouseTab tab, String code) {
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
