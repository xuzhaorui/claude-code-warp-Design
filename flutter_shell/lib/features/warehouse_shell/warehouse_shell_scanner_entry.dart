// Warehouse shell ↔ real ScannerPage wiring layer.
//
// Composes [WarehouseShellFormWiring] with the real [ScannerPage].
// When the user taps the scan card, a Navigator.push opens ScannerPage.
// After successful scan, the result is stored and the corresponding
// business form bottom sheet auto-opens for the current tab.
//
// No API calls, no real business logic.

import 'dart:async';

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
///   1. User taps scan card: [ScannerPage] opens
///   2. Scanner returns a code string via `Navigator.pop`
///   3. Code is stored as last scan result
///   4. [WidgetsBinding.instance.addPostFrameCallback] opens the
///      corresponding business form sheet for the current tab
///   5. Form uses fixture data — no real API
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
  State<WarehouseShellScannerEntry> createState() => _WarehouseShellScannerEntryState();
}

class _WarehouseShellScannerEntryState extends State<WarehouseShellScannerEntry> {
  String? _lastScanCode;

  @override
  Widget build(BuildContext context) {
    return WarehouseShellFormWiring(
      lastScanCode: _lastScanCode,
      onCheckoutSubmit: widget.onCheckoutSubmit,
      onReturnSubmit: widget.onReturnSubmit,
      onInventoryCheckSubmit: widget.onInventoryCheckSubmit,
      onScanRequested: (tab) => _handleScanRequest(context, tab),
    );
  }

  /// 1. Push ScannerPage, 2. await code, 3. store + auto-open form.
  Future<void> _handleScanRequest(BuildContext context, WarehouseTab tab) async {
    // Use a completer to bridge callback → await pattern.
    final completer = Completer<String?>();

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScannerPage(
          adapter: widget.adapter ?? RealMobileScannerAdapter(),
          onScanResult: (code) {
            widget.onScanResult?.call(code);
            completer.complete(code);
          },
          onClose: () {
            completer.complete(null);
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    final code = await completer.future;
    if (code == null || code.isEmpty || !mounted) return;

    setState(() => _lastScanCode = code);

    // Auto-open the corresponding business form for the scan tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openFormForTab(context, tab);
    });
  }

  void _openFormForTab(BuildContext context, WarehouseTab tab) {
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

// ── Duplicate fixture data (independent from form_wiring's _Fixture) ──

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
