import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/scanner/scanner_adapter.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellScannerEntry', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    testWidgets('renders scan card with qr icon', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      expect(find.byKey(const Key('scan_card')), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    testWidgets('tapping scan card opens ScannerPage', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pumpAndSettle();
      expect(find.text('退出扫码'), findsOneWidget);
    });

    testWidgets('mock adapter injectable', (tester) async {
      final adapter = MockScannerAdapter();
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: adapter),
      ));
      expect(adapter.status, ScannerStatus.idle);
    });

    testWidgets('renders 4 bottom tabs', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
      expect(find.text('设置'), findsWidgets);
    });

    testWidgets('no business logic triggered by default', (tester) async {
      bool businessTriggered = false;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onCheckoutSubmit: (_) => businessTriggered = true,
        ),
      ));
      expect(businessTriggered, isFalse);
    });

    testWidgets('scan result display preserved', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onScanResult: (code) => captured = code,
        ),
      ));
      expect(captured, isNull);
    });

    // flutter test runs in debug mode, so the kDebugMode-only manual input
    // overlay should render as a low-emphasis ghost trigger.
    testWidgets('debug manual input renders in debug mode', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      expect(find.textContaining('Debug'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsWidgets);
    });
  });
}
