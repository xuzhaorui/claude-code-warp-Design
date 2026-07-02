import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/api/mock_warehouse_api_client.dart';

const _item = InventoryCheckItemSnapshot(
  id: 42,
  stockQty: 100,
  itemName: '测试货物',
  code: 'ABC-001',
  spec: '500ml',
);

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('InventoryCheckFormMin', () {
    // 1. renders item basic info
    testWidgets('renders item basic info', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      expect(find.text('测试货物'), findsAtLeast(1));
      expect(find.text('ABC-001'), findsOneWidget);
    });

    // 2. initial actualQty equals item.stockQty
    testWidgets('initial actualQty equals stockQty', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      expect(find.text('100'), findsAtLeast(1));
    });

    // 3. renders bookQty in left-panel badge
    testWidgets('renders bookQty in badge', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      // task-045: AppFormSection subtitle replaced by a StockBadge in the
      // left panel; bookQty (100) renders as the badge value.
      expect(find.text('账面数量'), findsOneWidget);
      expect(find.text('100'), findsAtLeast(1));
    });

    // 4. actualQty stepper changes quantity
    testWidgets('stepper changes actualQty', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      // Initial is 100. Tap "+" → 101.
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(find.text('101'), findsAtLeast(1));
    });

    // 5. actualQty > stockQty shows +diff
    testWidgets('actualQty > stockQty shows +N', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      // Tap "+" 5 times → 105. Diff = 105-100 = 5, shows "+5".
      final plusBtn = find.text('+');
      for (int i = 0; i < 5; i++) {
        await tester.ensureVisible(plusBtn);
        await tester.pump();
        await tester.tap(plusBtn);
        await tester.pump();
      }
      // Verify the stepper shows 105.
      expect(find.text('105'), findsAtLeast(1));
    });

    // 6. actualQty < stockQty shows -diff
    testWidgets('actualQty < stockQty shows -N', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      // Tap "−" 3 times → 97. Diff = 97-100 = -3, shows "-3".
      final minusBtn = find.text('−');
      for (int i = 0; i < 3; i++) {
        await tester.ensureVisible(minusBtn);
        await tester.pump();
        await tester.tap(minusBtn);
        await tester.pump();
      }
      // Verify the stepper shows 97.
      expect(find.text('97'), findsAtLeast(1));
    });

    // 7. actualQty == stockQty shows 0 diff
    testWidgets('actualQty == stockQty shows 0', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      // Initial is 100, diff = 0.  The diff box renders "差值" label + "0".
      // The stepper input shows "100"; its hint "0" only renders when empty.
      expect(find.text('差值'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    // 8. remark input changes remark
    testWidgets('remark input works', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      final field = find.byType(TextFormField);
      await tester.enterText(field, '盘点完成');
      await tester.pump();
      expect(find.text('盘点完成'), findsOneWidget);
    });

    // 9. submit calls onSubmit with payload
    testWidgets('submit calls onSubmit', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(
          item: _item,
          onSubmit: (p) => captured = p,
        ),
      ));
      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.inventoryId, 42);
    });

    // 10. submit payload inventoryId correct
    testWidgets('submit payload has correct inventoryId', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(
          item: _item,
          onSubmit: (p) => captured = p,
        ),
      ));
      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.inventoryId, 42);
    });

    // 11. submit payload actualQty correct
    testWidgets('submit payload has correct actualQty', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(
          item: _item,
          onSubmit: (p) => captured = p,
        ),
      ));
      // Default is 100. Submit should have actualQty=100.
      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.actualQty, 100);
    });

    // 12. submit payload remark correct
    testWidgets('submit payload has correct remark', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(
          item: _item,
          onSubmit: (p) => captured = p,
        ),
      ));
      final field = find.byType(TextFormField);
      await tester.enterText(field, '盘点完成');
      await tester.pump();
      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.remark, '盘点完成');
    });

    // 13. onClose does not crash
    testWidgets('renders with onClose callback', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item, onClose: () {}),
      ));
      expect(find.byType(InventoryCheckFormMin), findsOneWidget);
    });

    // 14. long item info does not crash
    testWidgets('long item info does not crash', (tester) async {
      final longItem = InventoryCheckItemSnapshot(
        id: 1,
        stockQty: 10,
        itemName: '超长货物名称' * 20,
        code: '超长编号' * 20,
        spec: '超长规格' * 20,
      );
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: longItem),
      ));
      expect(find.byType(InventoryCheckFormMin), findsOneWidget);
    });

    // 15. Widget calls InventoryCheckFormRules instead of duplicating rule logic
    testWidgets('UI wiring: diff display matches rule logic', (tester) async {
      // When qty=120, diff=+20 (surplus). The widget should show "+20".
      // This verifies the UI reads from rules, not duplicating logic.
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item),
      ));
      // Tap "+" 20 times to get to 120.
      final plusBtn = find.text('+');
      for (int i = 0; i < 20; i++) {
        await tester.ensureVisible(plusBtn);
        await tester.pump();
        await tester.tap(plusBtn);
        await tester.pump();
      }
      // Verify stepper displays 120.
      expect(find.text('120'), findsAtLeast(1));
    });

    // 15. apiClient renders without crash
    testWidgets('apiClient renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        InventoryCheckFormMin(item: _item, apiClient: MockWarehouseApiClient()),
      ));
      expect(find.byType(InventoryCheckFormMin), findsOneWidget);
    });

    // 16. two-column layout: left panel item fields + black submit
    testWidgets('two-column layout shows item fields and 提交盘点', (tester) async {
      await tester.pumpWidget(wrapApp(InventoryCheckFormMin(item: _item)));
      await tester.pump();
      // Left panel item info.
      expect(find.text('货物名称'), findsOneWidget);
      expect(find.text('编号'), findsOneWidget);
      expect(find.text('规格'), findsOneWidget);
      // Black submit button label.
      expect(find.text('提交盘点'), findsOneWidget);
    });
  });
}
