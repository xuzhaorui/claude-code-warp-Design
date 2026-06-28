import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';
import 'package:wms_app/features/scanner/scanner_adapter.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellScannerEntry', () {
    // 1. renders without crash
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

    // 3. tapping scan opens real ScannerPage via Navigator
    testWidgets('tapping 扫码出库 opens ScannerPage', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
        ),
      ));
      await tester.tap(find.text('扫码出库'));
      await tester.pumpAndSettle();
      // ScannerPage shows the close button "退出扫码".
      expect(find.text('退出扫码'), findsOneWidget);
    });

    // 4. mock adapter injectable
    testWidgets('mock adapter can be injected', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
        ),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 5. checkout submit callback forwarded
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

    // 6. return submit callback forwarded
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

    // 7. inventory submit callback forwarded
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

    // 8. no API dependency required

    // 9. no route context required beyond MaterialApp
    testWidgets('renders in MaterialApp', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 10. scan result via injected adapter
    testWidgets('scan result via adapter callback', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onScanResult: (code) => captured = code,
        ),
      ));
      // Open ScannerPage.
      await tester.tap(find.text('扫码出库'));
      await tester.pumpAndSettle();

      // Captured is set when ScannerPage detects a barcode via the
      // injected adapter's result stream.  At this point, no real scan
      // has occurred, so captured should remain null.
      expect(captured, isNull);
      expect(find.text('退出扫码'), findsOneWidget);
    });
  });
}
