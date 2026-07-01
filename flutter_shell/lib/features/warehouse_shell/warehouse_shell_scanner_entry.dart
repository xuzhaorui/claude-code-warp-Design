// Warehouse shell ↔ real ScannerPage wiring layer.
//
// Composes [WarehouseShellFormWiring] with the real [ScannerPage].
// When the user taps the scan card, a [Navigator.push<String>] opens
// ScannerPage.  After the push returns, the scanned code is looked up
// via [WarehouseApiClient.findItemByCode] (or findBorrowersByQrcode
// for the return tab).  On success, the corresponding business form
// sheet auto-opens.  On failure, the code is still displayed but no
// form is opened.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
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
  });

  final ScannerAdapter? adapter;

  /// API client for scan lookup.  Inject [MockWarehouseApiClient] for tests,
  /// or [HttpWarehouseApiClient] for production.
  final WarehouseApiClient? apiClient;

  /// Display name of the currently active server, surfaced in the shell's
  /// status row.  Passed through to [WarehouseShellMin].
  final String? activeServerName;

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
  String? _lastScanCode;
  String? _scanError;
  WarehouseTab _activeTab = WarehouseTab.checkout;

  /// Per-tab records populated after successful submit.
  final Map<WarehouseTab, List<RecordItem>> _records = {};

  /// Guards against double-trigger during async API lookup.
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WarehouseShellFormWiring(
          lastScanCode: _lastScanCode,
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
        ),
        if (kDebugMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: _DebugManualCodeInput(
              onCodeEntered: (code) {
                _activeTab = WarehouseTab.checkout;
                setState(() {
                  _lastScanCode = code;
                  _scanError = null;
                });
                _lookupCode(context, WarehouseTab.checkout, code);
              },
            ),
          ),
      ],
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
      _lastScanCode = code;
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
          items = result.data!.map((p) => RecordItem(
            title: '出库 #${p.inventoryId}',
            detail: '数量: ${p.quantity}',
            status: '正常',
          )).toList();
        }
      case WarehouseTab.returnForm:
        final result = await api.fetchReturnRecords();
        if (result.isSuccess && result.data != null) {
          items = result.data!.map((p) => RecordItem(
            title: '归还 #${p.loanId}',
            detail: '数量: ${p.returnQty}',
          )).toList();
        }
      case WarehouseTab.inventoryCheck:
        final result = await api.fetchInventoryCheckRecords();
        if (result.isSuccess && result.data != null) {
          items = result.data!.map((p) => RecordItem(
            title: '盘点 #${p.inventoryId}',
            detail: '实盘: ${p.actualQty}',
          )).toList();
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

// ── Debug-only: manual code input for testing ──
//
// Component-local numeric constants (icon sizes) for the debug overlay.
// Per Design.md these are allowed as component-local constants and are not
// promoted to design tokens — this widget is debug-only, low-emphasis.
class _DBG {
  _DBG._();
  static const iconSize = 16.0;
  static const actionIconSize = 20.0;
  static const triggerHPad = AppSpacing.md;
  static const triggerVPad = AppSpacing.sm;
  static const inputWidth = 300.0;
  static const triggerMaxWidth = 260.0;
}

/// Debug-mode overlay widget to manually enter a scan code.
///
/// Uses an inline [TextField] instead of [showDialog] to avoid framework
/// assertion during dialog route unmount (`_dependents.isEmpty`).
/// Visual style is intentionally **low-emphasis** (outline/ghost): a thin
/// bordered pill trigger and a plain text field.  This is a test affordance,
/// not a primary action — production acceptance must use real paper-label
/// qrcode scanning.
///
/// Only visible in `kDebugMode` builds.
class _DebugManualCodeInput extends StatefulWidget {
  const _DebugManualCodeInput({required this.onCodeEntered});

  final ValueChanged<String> onCodeEntered;

  @override
  State<_DebugManualCodeInput> createState() => _DebugManualCodeInputState();
}

class _DebugManualCodeInputState extends State<_DebugManualCodeInput> {
  final _controller = TextEditingController();
  bool _showInput = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showInput)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(
              width: _DBG.inputWidth,
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '输入条码后按确认',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(AppRadii.sm),
                  ),
                  filled: true,
                  fillColor: AppDesignColors.surface,
                  isDense: true,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, size: _DBG.actionIconSize),
                        onPressed: () => _submit(_controller.text),
                        tooltip: '确认',
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: _DBG.actionIconSize),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _showInput = false);
                        },
                        tooltip: '取消',
                      ),
                    ],
                  ),
                ),
                style: AppTextStyles.body,
                onSubmitted: _submit,
              ),
            ),
          ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _DBG.triggerMaxWidth),
            child: Material(
              color: AppDesignColors.surface,
              borderRadius: BorderRadius.all(AppRadii.pill),
              child: InkWell(
                onTap: () => setState(() => _showInput = !_showInput),
                borderRadius: BorderRadius.all(AppRadii.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _DBG.triggerHPad,
                    vertical: _DBG.triggerVPad,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppDesignColors.borderMuted),
                    borderRadius: BorderRadius.all(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: _DBG.iconSize, color: AppDesignColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _showInput ? '关闭手动输入' : 'Debug: 手动输入扫码值',
                        style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submit(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    debugPrint('[ScannerFlow] debug manual code=$trimmed');
    _controller.clear();
    widget.onCodeEntered(trimmed);
  }
}
