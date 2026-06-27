// Scanner shell entry wiring layer.
//
// Composes [WarehouseShellFormWiring] with a placeholder scanner panel.
// When the user taps the scan entry button in the shell, a full-screen
// scanner panel appears with a mock scan button for testing.
//
// No real camera, no mobile_scanner, no API calls.

import 'package:flutter/material.dart';

import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form_rules.dart';
import 'warehouse_shell_form_wiring.dart';

// ── Component-local constants ──

class _SE {
  _SE._();
  static const mockScanCode = 'SKU-TEST-001';
}

// ── Public widget ──

/// Wires [WarehouseShellFormWiring] with a placeholder scanner panel.
///
/// Renders the full warehouse shell.  When the user taps a scan entry
/// button, a scanner placeholder panel slides up.  It provides a mock
/// scan button that fires [onScanResult] with a test code and a close
/// button to dismiss.
///
/// All form submit callbacks are forwarded to [WarehouseShellFormWiring].
class WarehouseShellScannerEntry extends StatefulWidget {
  const WarehouseShellScannerEntry({
    super.key,
    this.onScanRequested,
    this.onScanResult,
    this.onCheckoutSubmit,
    this.onReturnSubmit,
    this.onInventoryCheckSubmit,
  });

  /// Fired when the user taps the scan entry in the shell.
  final VoidCallback? onScanRequested;

  /// Fired when a mock scan produces a result code.
  final ValueChanged<String>? onScanResult;

  /// Forwarded to [WarehouseShellFormWiring].
  final ValueChanged<CheckoutSubmitPayload>? onCheckoutSubmit;

  /// Forwarded to [WarehouseShellFormWiring].
  final ValueChanged<ReturnSubmitPayload>? onReturnSubmit;

  /// Forwarded to [WarehouseShellFormWiring].
  final ValueChanged<InventoryCheckSubmitPayload>? onInventoryCheckSubmit;

  @override
  State<WarehouseShellScannerEntry> createState() =>
      _WarehouseShellScannerEntryState();
}

class _WarehouseShellScannerEntryState
    extends State<WarehouseShellScannerEntry> {
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shell + forms (always visible when not scanning)
        WarehouseShellFormWiring(
          onCheckoutSubmit: widget.onCheckoutSubmit,
          onReturnSubmit: widget.onReturnSubmit,
          onInventoryCheckSubmit: widget.onInventoryCheckSubmit,
          onScanRequested: () {
            setState(() => _scanning = true);
            widget.onScanRequested?.call();
          },
        ),
        // Scanner overlay
        if (_scanning) _ScannerPanel(
          onClose: () => setState(() => _scanning = false),
          onMockScan: () {
            widget.onScanResult?.call(_SE.mockScanCode);
          },
        ),
      ],
    );
  }
}

// ── Scanner panel ──

class _ScannerPanel extends StatelessWidget {
  const _ScannerPanel({
    required this.onClose,
    required this.onMockScan,
  });

  final VoidCallback onClose;
  final VoidCallback onMockScan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('扫码',
                        style: AppTextStyles.title),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close,
                        color: AppDesignColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Description
              Text(
                '此处将接入真实扫码能力',
                style: AppTextStyles.body.copyWith(
                  color: AppDesignColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Mock scan button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: _ActionCard(
                    label: '模拟扫码 (SKU-TEST-001)',
                    icon: Icons.qr_code_scanner,
                    onTap: onMockScan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable action card ──

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignColors.surfaceMuted,
      borderRadius: BorderRadius.all(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.all(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppDesignColors.textPrimary),
              const SizedBox(width: AppSpacing.md),
              Text(label,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
