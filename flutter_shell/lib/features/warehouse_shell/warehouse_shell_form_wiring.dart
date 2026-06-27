// Warehouse shell ↔ business form sheets wiring layer.
//
// Composes [WarehouseShellMin] with [BusinessFormSheets]: when the user taps
// a form entry button in the shell, this layer opens the corresponding
// business form bottom sheet with fixture data.
//
// No API calls, no live data loading, no routing.

import 'package:flutter/material.dart';

import '../../components/app_bottom_sheet.dart';
import '../business_forms/business_form_sheets.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import 'warehouse_shell.dart';

// ── Private fixture data ──

/// Minimal fixture snapshots used to render business form sheets.
///
/// These are NOT representative of real API data.  They exist only to
/// verify the UI wiring path from shell → business form sheet.
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

// ── Public widget ──

/// Wires [WarehouseShellMin] to [BusinessFormSheets].
///
/// Renders the shell with three tabs.  When the user taps a form entry
/// button, this widget opens the corresponding [showAppBottomSheet] modal
/// with fixture data and forwards submit payloads via callbacks.
class WarehouseShellFormWiring extends StatelessWidget {
  const WarehouseShellFormWiring({
    super.key,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
    this.onScanRequested,
  });

  /// Called when the checkout form is submitted.
  final ValueChanged<CheckoutSubmitPayload>? onCheckoutSubmit;

  /// Called when the return form is submitted.
  final ValueChanged<ReturnSubmitPayload>? onReturnSubmit;

  /// Called when the inventory check form is submitted.
  final ValueChanged<InventoryCheckSubmitPayload>? onInventoryCheckSubmit;

  /// Fired when the user taps the scan entry point.
  final VoidCallback? onScanRequested;

  @override
  Widget build(BuildContext context) {
    return WarehouseShellMin(
      onScanRequested: onScanRequested,
      onCheckoutRequested: () => _openCheckoutSheet(context),
      onReturnRequested: () => _openReturnSheet(context),
      onInventoryCheckRequested: () => _openInventorySheet(context),
    );
  }

  void _openCheckoutSheet(BuildContext context) {
    showCheckoutFormSheet(
      context: context,
      item: _Fixture.checkoutItem,
      onSubmit: onCheckoutSubmit,
    );
  }

  void _openReturnSheet(BuildContext context) {
    showReturnFormSheet(
      context: context,
      record: _Fixture.returnRecord,
      onSubmit: onReturnSubmit,
    );
  }

  void _openInventorySheet(BuildContext context) {
    showInventoryCheckFormSheet(
      context: context,
      item: _Fixture.inventoryItem,
      onSubmit: onInventoryCheckSubmit,
    );
  }
}
