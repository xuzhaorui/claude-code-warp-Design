// Warehouse shell ↔ real ScannerPage wiring layer.
//
// Composes [WarehouseShellFormWiring] with the real [ScannerPage].
// When the user taps the scan entry button in the shell, a
// [Navigator.push] opens [ScannerPage] with a [RealMobileScannerAdapter]
// (or an injected mock adapter for testing).
//
// No API calls, no business logic.

import 'package:flutter/material.dart';

import '../../pages/scanner_page.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import '../scanner/mobile_scanner_adapter.dart';
import '../scanner/scanner_adapter.dart';
import 'warehouse_shell_form_wiring.dart';

// ── Public widget ──

/// Wires [WarehouseShellFormWiring] to [ScannerPage].
///
/// When the user taps a scan entry button, a full-screen [ScannerPage] is
/// pushed via [Navigator.push].  The scanner uses [RealMobileScannerAdapter]
/// by default, or an injected [adapter] for testing.
class WarehouseShellScannerEntry extends StatelessWidget {
  const WarehouseShellScannerEntry({
    super.key,
    this.adapter,
    this.onScanResult,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
  });

  /// Optional scanner adapter (inject [MockScannerAdapter] for tests).
  /// When null, a [RealMobileScannerAdapter] is used.
  final ScannerAdapter? adapter;

  /// Fired when a scan result is received from [ScannerPage].
  final ValueChanged<String>? onScanResult;

  /// Forwarded to [WarehouseShellFormWiring].
  final ValueChanged<CheckoutSubmitPayload>? onCheckoutSubmit;

  /// Forwarded to [WarehouseShellFormWiring].
  final ValueChanged<ReturnSubmitPayload>? onReturnSubmit;

  /// Forwarded to [WarehouseShellFormWiring].
  final ValueChanged<InventoryCheckSubmitPayload>? onInventoryCheckSubmit;

  @override
  Widget build(BuildContext context) {
    return WarehouseShellFormWiring(
      onCheckoutSubmit: onCheckoutSubmit,
      onReturnSubmit: onReturnSubmit,
      onInventoryCheckSubmit: onInventoryCheckSubmit,
      onScanRequested: () => _openScanner(context),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScannerPage(
          adapter: adapter ?? RealMobileScannerAdapter(),
          onScanResult: (code) {
            onScanResult?.call(code);
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
