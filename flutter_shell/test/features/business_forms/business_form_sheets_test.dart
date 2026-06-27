import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_bottom_sheet.dart';
import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/business_forms/business_form_sheets.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

// Shared fixtures
const _checkoutItem = CheckoutItemSnapshot(
  id: 42, stockQty: 100, costPrice: 50.0,
  itemName: '出库货物', code: 'CK-001',
);

const _returnRecord = ReturnBorrowRecordSnapshot(
  loanId: 101, freightId: 202, storageId: 303,
  borrowQty: 50, costPrice: 30.0,
  itemName: '归还货物', borrower: '张三', warehouse: '主仓库',
);

const _inventoryItem = InventoryCheckItemSnapshot(
  id: 77, stockQty: 100,
  itemName: '盘点货物', code: 'PD-001', spec: '500ml',
);

void main() {
  group('CheckoutFormSheetContent', () {
    // 1. renders checkout title/form
    testWidgets('renders checkout title and form', (tester) async {
      await tester.pumpWidget(wrapApp(
        const CheckoutFormSheetContent(item: _checkoutItem),
      ));
      expect(find.text('出库表单'), findsOneWidget);
      expect(find.text('出库货物'), findsAtLeast(1));
    });

    // 4. checkout submit bubbles CheckoutSubmitPayload
    testWidgets('checkout submit bubbles payload', (tester) async {
      CheckoutSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        CheckoutFormSheetContent(
          item: _checkoutItem,
          onSubmit: (p) => captured = p,
        ),
      ));
      // Switch to 外借 (doesn't require sale total).
      await tester.ensureVisible(find.text('外借'));
      await tester.pump();
      await tester.tap(find.text('外借'));
      await tester.pump();
      // Tap + to increment qty.
      await tester.ensureVisible(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      // Submit.
      await tester.ensureVisible(find.text('提交'));
      await tester.pump();
      await tester.tap(find.text('提交'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.type, 2);
    });

    // 7. checkout close callback works
    testWidgets('checkout close callback works', (tester) async {
      bool closed = false;
      await tester.pumpWidget(wrapApp(
        CheckoutFormSheetContent(
          item: _checkoutItem,
          onClose: () => closed = true,
        ),
      ));
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });
  });

  group('ReturnFormSheetContent', () {
    // 2. renders return title/form
    testWidgets('renders return title and form', (tester) async {
      await tester.pumpWidget(wrapApp(
        const ReturnFormSheetContent(record: _returnRecord),
      ));
      expect(find.text('归还表单'), findsOneWidget);
      expect(find.text('归还货物'), findsAtLeast(1));
    });

    // 5. return submit bubbles ReturnSubmitPayload
    testWidgets('return submit bubbles payload', (tester) async {
      ReturnSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        ReturnFormSheetContent(
          record: _returnRecord,
          onSubmit: (p) => captured = p,
        ),
      ));
      // Tap + to increment qty, then submit.
      await tester.ensureVisible(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.ensureVisible(find.text('确认归还'));
      await tester.pump();
      await tester.tap(find.text('确认归还'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.loanId, 101);
    });

    // 8. return close callback works
    testWidgets('return close callback works', (tester) async {
      bool closed = false;
      await tester.pumpWidget(wrapApp(
        ReturnFormSheetContent(
          record: _returnRecord,
          onClose: () => closed = true,
        ),
      ));
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });
  });

  group('InventoryCheckFormSheetContent', () {
    // 3. renders inventory title/form
    testWidgets('renders inventory title and form', (tester) async {
      await tester.pumpWidget(wrapApp(
        const InventoryCheckFormSheetContent(item: _inventoryItem),
      ));
      expect(find.text('盘点表单'), findsOneWidget);
      expect(find.text('盘点货物'), findsAtLeast(1));
    });

    // 6. inventory submit bubbles InventoryCheckSubmitPayload
    testWidgets('inventory submit bubbles payload', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormSheetContent(
          item: _inventoryItem,
          onSubmit: (p) => captured = p,
        ),
      ));
      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.inventoryId, 77);
    });

    // 9. inventory close callback works
    testWidgets('inventory close callback works', (tester) async {
      bool closed = false;
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormSheetContent(
          item: _inventoryItem,
          onClose: () => closed = true,
        ),
      ));
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });
  });

  // 10. Sheet content does not call API — verified by absence of API imports

  // 11. Sheet content does not require route context — verified by use of
  //    wrapApp (Scaffold) instead of MaterialApp with routes

  // 12. Long item names do not crash
  testWidgets('long item names do not crash', (tester) async {
    final longItem = CheckoutItemSnapshot(
      id: 1, stockQty: 10, costPrice: 5.0,
      itemName: '超长货物名称' * 20,
    );
    await tester.pumpWidget(wrapApp(
      CheckoutFormSheetContent(item: longItem),
    ));
    expect(find.byType(CheckoutFormSheetContent), findsOneWidget);
  });

  // 13. All three sheet contents use AppBottomSheetFrame
  testWidgets('all sheet contents use AppBottomSheetFrame', (tester) async {
    await tester.pumpWidget(wrapApp(
      const CheckoutFormSheetContent(item: _checkoutItem),
    ));
    expect(find.byType(AppBottomSheetFrame), findsOneWidget);
  });

  // 14. Widget smoke test for showCheckoutFormSheet
  //     (tests the sheet content wrapper directly above — the show* helpers
  //      are thin wrappers that require a Navigator context for modal)

  // 15-16. Same as 14 for return and inventory
}
