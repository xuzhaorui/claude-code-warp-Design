// Warehouse shell ↔ real ScannerPage wiring layer.
//
// Composes [WarehouseShellFormWiring] with the real [ScannerPage].
// When the user taps the scan card, a [Navigator.push<String>] opens
// ScannerPage.  The scanner page calls [Navigator.pop(scannerContext, code)]
// from its [onScanResult] handler.  After the push returns, the scanned
// code is stored and the corresponding business form sheet auto-opens
// for the current tab.
//
// No API calls, no real business logic.

import 'package:flutter/material.dart';

import '../../pages/scanner_page.dart';
import '../business_forms/business_form_sheets.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import '../scanner/mobile_scanner_adapter.dart';
import '../scanner/scanner_adapter.dart';
import 'warehouse_shell.dart';
import 'warehouse_shell_form_wiring.dart';

// ── Public widget ──

/// Wires [WarehouseShellFormWiring] to [ScannerPage].
///
/// Scan flow:
///   1. User taps scan card → [Navigator.push<String>(ScannerPage)]
///   2. ScannerPage detects code → calls [Navigator.pop(scannerContext, code)]
///   3. Await returns the code → store as last scan result
///   4. [WidgetsBinding.instance.addPostFrameCallback] opens the
///      corresponding business form sheet for the current tab
class WarehouseShellScannerEntry extends StatefulWidget {
  const WarehouseShellScannerEntry({
    super.key,
    this.adapter,
    this.onScanResult,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
  });

  final ScannerAdapter? adapter;
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

  @override
  Widget build(BuildContext context) {
    return WarehouseShellFormWiring(
      lastScanCode: _lastScanCode,
      onCheckoutSubmit: widget.onCheckoutSubmit,
      onReturnSubmit: widget.onReturnSubmit,
      onInventoryCheckSubmit: widget.onInventoryCheckSubmit,
      onScanRequested: (tab) => _openScanner(context, tab),
    );
  }

  /// Push [ScannerPage], await code via Navigator-pop contract.
  Future<void> _openScanner(BuildContext context, WarehouseTab tab) async {
    debugPrint('[ScannerFlow] open scanner tab=$tab');

    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (scannerContext) => ScannerPage(
          adapter: widget.adapter ?? RealMobileScannerAdapter(),
          onScanResult: (code) {
            debugPrint('[ScannerFlow] scanner result=$code');
            widget.onScanResult?.call(code);
            // Pop with code using scanner's own context.
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

    setState(() => _lastScanCode = code);

    // Auto-open the corresponding business form for the scan tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _openBusinessFormForTab(context, tab, code);
    });
  }

  void _openBusinessFormForTab(
      BuildContext context, WarehouseTab tab, String code) {
    debugPrint('[ScannerFlow] open $tab form after scan code=$code');
    switch (tab) {
      case WarehouseTab.checkout:
        showCheckoutFormSheet(
          context: context,
          item: _Fixture.checkoutItem,
          onSubmit: widget.onCheckoutSubmit,
        );
      case WarehouseTab.returnForm:
        showReturnFormSheet(
          context: context,
          record: _Fixture.returnRecord,
          onSubmit: widget.onReturnSubmit,
        );
      case WarehouseTab.inventoryCheck:
        showInventoryCheckFormSheet(
          context: context,
          item: _Fixture.inventoryItem,
          onSubmit: widget.onInventoryCheckSubmit,
        );
      case WarehouseTab.settings:
        break;
    }
  }
}

// ── Fixture data ──

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
