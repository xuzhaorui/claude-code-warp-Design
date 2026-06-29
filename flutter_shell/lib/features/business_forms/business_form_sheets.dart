import 'package:flutter/material.dart';

import '../../components/app_bottom_sheet.dart';
import '../api/warehouse_api_client.dart';
import '../checkout/checkout_form.dart';
import '../checkout/checkout_form_rules.dart';
import '../inventory_check/inventory_check_form.dart';
import '../inventory_check/inventory_check_form_rules.dart';
import '../return_form/return_form.dart';
import '../return_form/return_form_rules.dart';

// ── 1. Checkout ──

class CheckoutFormSheetContent extends StatelessWidget {
  const CheckoutFormSheetContent({
    super.key,
    required this.item,
    this.operatorName,
    this.apiClient,
    this.onSubmit,
    this.onClose,
    this.onSubmitSuccess,
  });

  final CheckoutItemSnapshot item;
  final String? operatorName;
  final WarehouseApiClient? apiClient;
  final ValueChanged<CheckoutSubmitPayload>? onSubmit;
  final VoidCallback? onClose;
  final VoidCallback? onSubmitSuccess;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      title: '出库表单', onClose: onClose,
      child: CheckoutFormMin(item: item, operatorName: operatorName,
          apiClient: apiClient, onSubmit: onSubmit, onClose: onClose,
          onSubmitSuccess: onSubmitSuccess),
    );
  }
}

Future<void> showCheckoutFormSheet({
  required BuildContext context, required CheckoutItemSnapshot item,
  String? operatorName, WarehouseApiClient? apiClient,
  ValueChanged<CheckoutSubmitPayload>? onSubmit, VoidCallback? onSubmitSuccess,
}) {
  return showAppBottomSheet(
    context: context, title: '出库表单',
    child: CheckoutFormMin(item: item, operatorName: operatorName,
        apiClient: apiClient, onSubmit: onSubmit,
        onSubmitSuccess: onSubmitSuccess,
        onClose: () => Navigator.of(context).pop()),
  );
}

// ── 2. Return ──

class ReturnFormSheetContent extends StatelessWidget {
  const ReturnFormSheetContent({
    super.key, required this.record, this.operatorName,
    this.apiClient, this.onSubmit, this.onClose, this.onSubmitSuccess,
  });

  final ReturnBorrowRecordSnapshot record;
  final String? operatorName;
  final WarehouseApiClient? apiClient;
  final ValueChanged<ReturnSubmitPayload>? onSubmit;
  final VoidCallback? onClose;
  final VoidCallback? onSubmitSuccess;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      title: '归还表单', onClose: onClose,
      child: ReturnFormMin(record: record, operatorName: operatorName,
          apiClient: apiClient, onSubmit: onSubmit, onClose: onClose,
          onSubmitSuccess: onSubmitSuccess),
    );
  }
}

Future<void> showReturnFormSheet({
  required BuildContext context, required ReturnBorrowRecordSnapshot record,
  String? operatorName, WarehouseApiClient? apiClient,
  ValueChanged<ReturnSubmitPayload>? onSubmit, VoidCallback? onSubmitSuccess,
}) {
  return showAppBottomSheet(
    context: context, title: '归还表单',
    child: ReturnFormMin(record: record, operatorName: operatorName,
        apiClient: apiClient, onSubmit: onSubmit,
        onSubmitSuccess: onSubmitSuccess,
        onClose: () => Navigator.of(context).pop()),
  );
}

// ── 3. Inventory Check ──

class InventoryCheckFormSheetContent extends StatelessWidget {
  const InventoryCheckFormSheetContent({
    super.key, required this.item, this.operatorName,
    this.apiClient, this.onSubmit, this.onClose, this.onSubmitSuccess,
  });

  final InventoryCheckItemSnapshot item;
  final String? operatorName;
  final WarehouseApiClient? apiClient;
  final ValueChanged<InventoryCheckSubmitPayload>? onSubmit;
  final VoidCallback? onClose;
  final VoidCallback? onSubmitSuccess;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      title: '盘点表单', onClose: onClose,
      child: InventoryCheckFormMin(item: item, operatorName: operatorName,
          apiClient: apiClient, onSubmit: onSubmit, onClose: onClose,
          onSubmitSuccess: onSubmitSuccess),
    );
  }
}

Future<void> showInventoryCheckFormSheet({
  required BuildContext context, required InventoryCheckItemSnapshot item,
  String? operatorName, WarehouseApiClient? apiClient,
  ValueChanged<InventoryCheckSubmitPayload>? onSubmit, VoidCallback? onSubmitSuccess,
}) {
  return showAppBottomSheet(
    context: context, title: '盘点表单',
    child: InventoryCheckFormMin(item: item, operatorName: operatorName,
        apiClient: apiClient, onSubmit: onSubmit,
        onSubmitSuccess: onSubmitSuccess,
        onClose: () => Navigator.of(context).pop()),
  );
}
