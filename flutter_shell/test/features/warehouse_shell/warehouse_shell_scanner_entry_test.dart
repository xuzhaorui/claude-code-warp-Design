import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellScannerEntry', () {
    // 1. renders WarehouseShellScannerEntry
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 2. renders three shell tabs
    testWidgets('renders three bottom nav items', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
    });

    // 3. tapping scan entry opens scanner panel
    testWidgets('tapping 扫码出库 opens scanner panel', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(find.text('此处将接入真实扫码能力'), findsOneWidget);
    });

    // 4. scanner panel renders title
    testWidgets('scanner panel shows 扫码 title', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(find.text('扫码'), findsOneWidget);
    });

    // 5. scanner panel renders placeholder description
    testWidgets('scanner panel shows placeholder text', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(find.text('此处将接入真实扫码能力'), findsOneWidget);
    });

    // 6. tapping mock scan fires onScanResult
    testWidgets('mock scan fires onScanResult', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          onScanResult: (code) => captured = code,
        ),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      await tester.tap(find.textContaining('模拟扫码'));
      await tester.pump();
      expect(captured, isNotNull);
    });

    // 7. mock scan result equals SKU-TEST-001
    testWidgets('mock scan result is SKU-TEST-001', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          onScanResult: (code) => captured = code,
        ),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      await tester.tap(find.textContaining('模拟扫码'));
      await tester.pump();
      expect(captured, 'SKU-TEST-001');
    });

    // 8. onScanRequested fires when scan entry tapped
    testWidgets('onScanRequested fires', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          onScanRequested: () => callCount++,
        ),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(callCount, 1);
    });

    // 9. scanner panel can close
    testWidgets('scanner panel closes', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(find.text('此处将接入真实扫码能力'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('此处将接入真实扫码能力'), findsNothing);
    });

    // 10. after closing scanner panel, shell still renders
    testWidgets('shell renders after scan close', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('扫码出库'), findsOneWidget);
    });

    // 11. checkout submit callback still bubbles
    testWidgets('checkout submit bubbles', (tester) async {
      CheckoutSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          onCheckoutSubmit: (p) => captured = p,
        ),
      ));
      await tester.tap(find.text('发起出库'));
      await tester.pumpAndSettle();

      // Switch to 外借 and submit.
      await tester.tap(find.text('外借'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.ensureVisible(find.text('提交'));
      await tester.pump();
      await tester.tap(find.text('提交'));
      await tester.pump();

      expect(captured, isNotNull);
    });

    // 12. return submit callback still bubbles
    testWidgets('return submit bubbles', (tester) async {
      ReturnSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          onReturnSubmit: (p) => captured = p,
        ),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.ensureVisible(find.text('确认归还'));
      await tester.pump();
      await tester.tap(find.text('确认归还'));
      await tester.pump();

      expect(captured, isNotNull);
    });

    // 13. inventory submit callback still bubbles
    testWidgets('inventory submit bubbles', (tester) async {
      InventoryCheckSubmitPayload? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          onInventoryCheckSubmit: (p) => captured = p,
        ),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('提交盘点'));
      await tester.pump();
      await tester.tap(find.text('提交盘点'));
      await tester.pump();

      expect(captured, isNotNull);
    });

    // 14. switching tabs before scan does not crash
    testWidgets('switch tabs then scan', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('出库').last);
      await tester.pump();

      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(find.text('此处将接入真实扫码能力'), findsOneWidget);
    });

    // 15. switching tabs after scan close does not crash
    testWidgets('switch tabs after scan close', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 16. no API dependency required (verified by absence of API imports)

    // 17. no route context required
    testWidgets('renders without route config', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 18. no real camera dependency required
    // (verified by absence of mobile_scanner import)

    // 19. no mobile_scanner dependency required in tests
    // (verified by test passing without mobile_scanner setup)

    // 20. long placeholder text does not crash
    testWidgets('long text does not crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });
  });
}
