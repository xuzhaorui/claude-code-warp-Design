// Business form bottom-sheet integration layer.
//
// Provides one [AppBottomSheetFrame] wrapper and one [showAppBottomSheet]
// wrapper per business form (checkout / return / inventory check).
//
// Usage (test-safe):
// ```dart
// await tester.pumpWidget(CheckoutFormSheetContent(...));
// ```
//
// Usage (modal):
// ```dart
// showCheckoutFormSheet(context: context, item: item, onSubmit: ...);
// ```

import 'package:flutter/material.dart';

import '../../components/app_bottom_sheet.dart';
import '../checkout/checkout_form.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form.dart';
import '../return_form/return_form_rules.dart';

// ────────────────────────────────────────────────────────────
//  1. CheckoutFormSheet
// ────────────────────────────────────────────────────────────

/// [AppBottomSheetFrame] wrapper around [CheckoutFormMin].
///
/// Testable: pump this widget directly without a modal route.
class CheckoutFormSheetContent extends StatelessWidget {
  const CheckoutFormSheetContent({
    super.key,
    required this.item,
    this.operatorName,
    this.onSubmit,
    this.onClose,
  });

  final CheckoutItemSnapshot item;
  final String? operatorName;
  final ValueChanged<CheckoutSubmitPayload>? onSubmit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      title: '出库表单',
      onClose: onClose,
      child: CheckoutFormMin(
        item: item,
        operatorName: operatorName,
        onSubmit: onSubmit,
        onClose: onClose,
      ),
    );
  }
}

/// Opens a modal bottom sheet with [CheckoutFormMin].
Future<void> showCheckoutFormSheet({
  required BuildContext context,
  required CheckoutItemSnapshot item,
  String? operatorName,
  ValueChanged<CheckoutSubmitPayload>? onSubmit,
}) {
  return showAppBottomSheet(
    context: context,
    title: '出库表单',
    child: CheckoutFormMin(
      item: item,
      operatorName: operatorName,
      onSubmit: onSubmit,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

// ────────────────────────────────────────────────────────────
//  2. ReturnFormSheet
// ────────────────────────────────────────────────────────────

/// [AppBottomSheetFrame] wrapper around [ReturnFormMin].
class ReturnFormSheetContent extends StatelessWidget {
  const ReturnFormSheetContent({
    super.key,
    required this.record,
    this.operatorName,
    this.onSubmit,
    this.onClose,
  });

  final ReturnBorrowRecordSnapshot record;
  final String? operatorName;
  final ValueChanged<ReturnSubmitPayload>? onSubmit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      title: '归还表单',
      onClose: onClose,
      child: ReturnFormMin(
        record: record,
        operatorName: operatorName,
        onSubmit: onSubmit,
        onClose: onClose,
      ),
    );
  }
}

/// Opens a modal bottom sheet with [ReturnFormMin].
Future<void> showReturnFormSheet({
  required BuildContext context,
  required ReturnBorrowRecordSnapshot record,
  String? operatorName,
  ValueChanged<ReturnSubmitPayload>? onSubmit,
}) {
  return showAppBottomSheet(
    context: context,
    title: '归还表单',
    child: ReturnFormMin(
      record: record,
      operatorName: operatorName,
      onSubmit: onSubmit,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

// ────────────────────────────────────────────────────────────
//  3. InventoryCheckFormSheet
// ────────────────────────────────────────────────────────────

/// [AppBottomSheetFrame] wrapper around [InventoryCheckFormMin].
class InventoryCheckFormSheetContent extends StatelessWidget {
  const InventoryCheckFormSheetContent({
    super.key,
    required this.item,
    this.operatorName,
    this.onSubmit,
    this.onClose,
  });

  final InventoryCheckItemSnapshot item;
  final String? operatorName;
  final ValueChanged<InventoryCheckSubmitPayload>? onSubmit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      title: '盘点表单',
      onClose: onClose,
      child: InventoryCheckFormMin(
        item: item,
        operatorName: operatorName,
        onSubmit: onSubmit,
        onClose: onClose,
      ),
    );
  }
}

/// Opens a modal bottom sheet with [InventoryCheckFormMin].
Future<void> showInventoryCheckFormSheet({
  required BuildContext context,
  required InventoryCheckItemSnapshot item,
  String? operatorName,
  ValueChanged<InventoryCheckSubmitPayload>? onSubmit,
}) {
  return showAppBottomSheet(
    context: context,
    title: '盘点表单',
    child: InventoryCheckFormMin(
      item: item,
      operatorName: operatorName,
      onSubmit: onSubmit,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
