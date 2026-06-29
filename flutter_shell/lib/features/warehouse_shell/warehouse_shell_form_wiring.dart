// Warehouse shell ↔ business form sheets wiring layer.
//
// Composes [WarehouseShellMin] with form-opening callbacks.
// When the user scans a code in the current tab, the scanner entry
// (not this layer) opens the corresponding form sheet with fixture data.
//
// No API calls, no live data loading, no routing.

import 'package:flutter/material.dart';

import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import 'warehouse_shell.dart';

// ── Public widget ──

/// Wires [WarehouseShellMin] to form-opening callbacks.
///
/// Passes through [lastScanCode] and [onScanRequested] to the shell.
/// The scanner entry layer handles the actual scan → form open flow.
class WarehouseShellFormWiring extends StatelessWidget {
  const WarehouseShellFormWiring({
    super.key,
    this.lastScanCode,
    this.scanError,
    this.records,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
    this.onScanRequested,
    this.onSettingsRequested,
  });

  final String? lastScanCode;
  final String? scanError;

  /// Records to display in the current tab.
  final List<RecordItem>? records;
  final ValueChanged<CheckoutSubmitPayload>? onCheckoutSubmit;
  final ValueChanged<ReturnSubmitPayload>? onReturnSubmit;
  final ValueChanged<InventoryCheckSubmitPayload>? onInventoryCheckSubmit;

  /// Fired with the current tab when scan card is tapped.
  final ValueChanged<WarehouseTab>? onScanRequested;

  /// Fired when settings page navigation is requested.
  final VoidCallback? onSettingsRequested;

  @override
  Widget build(BuildContext context) {
    return WarehouseShellMin(
      lastScanCode: lastScanCode,
      scanError: scanError,
      records: records,
      onScanRequested: onScanRequested,
      onSettingsRequested: onSettingsRequested,
    );
  }
}
