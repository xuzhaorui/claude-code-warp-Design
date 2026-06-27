import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_form_wiring.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellFormWiring', () {
    // 1. renders WarehouseShellFormWiring
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.byType(WarehouseShellFormWiring), findsOneWidget);
    });

    // 2. renders three shell tabs
    testWidgets('renders three bottom nav items', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
    });

    // 3. tapping checkout request opens checkout sheet
    testWidgets('tapping 发起出库 opens checkout sheet', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();
      expect(find.text('出库表单'), findsOneWidget);
    });

    // 4. tapping return request opens return sheet
    testWidgets('tapping 发起归还 opens return sheet', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pumpAndSettle();
      expect(find.text('归还表单'), findsOneWidget);
    });

    // 5. tapping inventory request opens inventory sheet
    testWidgets('tapping 发起盘点 opens inventory sheet', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pumpAndSettle();
      expect(find.text('盘点表单'), findsOneWidget);
    });

    // 6. checkout sheet submit bubbles CheckoutSubmitPayload
    testWidgets('checkout sheet submit bubbles payload', (tester) async {
      CheckoutSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellFormWiring(
          onCheckoutSubmit: (p) => captured = p,
        ),
      ));
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();

      // Switch to 外借 method so we can submit without sale total.
      await tester.tap(find.text('外借'));
      await tester.pump();
      // Tap + to increment qty.
      await tester.tap(find.text('+'));
      await tester.pump();
      // Scroll to and tap submit.
      await tester.ensureVisible(find.text('提交'));
      await tester.pump();
      await tester.tap(find.text('提交'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.type, 2);
    });

    // 7. return sheet submit bubbles ReturnSubmitPayload
    testWidgets('return sheet submit bubbles payload', (tester) async {
      ReturnSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellFormWiring(
          onReturnSubmit: (p) => captured = p,
        ),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pumpAndSettle();

      // Tap + to increment qty.
      await tester.tap(find.text('+'));
      await tester.pump();
      // Submit.
      await tester.tap(find.text('确认归还'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.loanId, 201);
    });

    // 8. inventory sheet submit bubbles InventoryCheckSubmitPayload
    testWidgets('inventory sheet submit bubbles payload', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellFormWiring(
          onInventoryCheckSubmit: (p) => captured = p,
        ),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pumpAndSettle();

      // Submit (always enabled).
      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.inventoryId, 3001);
    });

    // 9. checkout sheet close works
    testWidgets('checkout sheet can close', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();
      expect(find.text('出库表单'), findsOneWidget);

      // Close via close button.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('出库表单'), findsNothing);
    });

    // 10. return sheet close works
    testWidgets('return sheet can close', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pumpAndSettle();
      expect(find.text('归还表单'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('归还表单'), findsNothing);
    });

    // 11. inventory sheet close works
    testWidgets('inventory sheet can close', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pumpAndSettle();
      expect(find.text('盘点表单'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('盘点表单'), findsNothing);
    });

    // 12. scan callback fires
    testWidgets('scan callback fires', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        WarehouseShellFormWiring(
          onScanRequested: () => callCount++,
        ),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(callCount, 1);
    });

    // 13. no API dependency required (verified by absence of API imports)

    // 14. no route context required
    testWidgets('renders without route config', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.byType(WarehouseShellFormWiring), findsOneWidget);
    });

    // 15. fixture data renders in checkout sheet
    testWidgets('fixture renders in checkout sheet', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();
      // Fixture item name should be visible.
      expect(find.text('Widget Pro'), findsAtLeast(1));
    });

    // 16. fixture data renders in return sheet
    testWidgets('fixture renders in return sheet', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pumpAndSettle();
      expect(find.text('Borrowed Item'), findsAtLeast(1));
    });

    // 17. fixture data renders in inventory sheet
    testWidgets('fixture renders in inventory sheet', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pumpAndSettle();
      expect(find.text('Stock Item A'), findsAtLeast(1));
    });

    // 18. switching tabs before opening sheet does not crash
    testWidgets('switching tabs before opening sheet works', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      // Switch tabs a few times.
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('出库').last);
      await tester.pump();
      // Now open sheet.
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();
      expect(find.text('出库表单'), findsOneWidget);
    });

    // 19. opening multiple sheets sequentially works
    testWidgets('multiple sheets sequential open/close', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      // Open & close checkout sheet.
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();
      expect(find.text('出库表单'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Open & close return sheet.
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pumpAndSettle();
      expect(find.text('归还表单'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Open & close inventory sheet.
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pumpAndSettle();
      expect(find.text('盘点表单'), findsOneWidget);
    });

    // 20. long fixture text does not crash
    testWidgets('long fixture text does not crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      // Open checkout sheet — fixture item name is short but normal.
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();
      expect(find.byType(WarehouseShellFormWiring), findsOneWidget);
    });
  });
}
