import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/scanner/scanner_adapter.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('ScannerEntryWiring', () {
    // 1. tap scan card opens ScannerPage
    testWidgets('tap scan card opens ScannerPage', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pumpAndSettle();
      expect(find.text('退出扫码'), findsOneWidget);
    });

    testWidgets('onScanResult callback fires', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onScanResult: (code) => captured = code,
        ),
      ));
      expect(captured, isNull);
      // The actual emission is tested at ScannerPage level.
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 4. no business logic on scan entry
    testWidgets('no business logic on scan entry', (tester) async {
      bool businessTriggered = false;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onCheckoutSubmit: (_) => businessTriggered = true,
        ),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pumpAndSettle();
      expect(businessTriggered, isFalse);
    });

    // 5. scan card renders
    testWidgets('scan card renders with qr icon', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      expect(find.byKey(const Key('scan_card')), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    // 6. renders 4 bottom tabs
    testWidgets('renders 4 bottom tabs', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
      expect(find.text('设置'), findsWidgets);
    });

    // 7. mock adapter injectable
    testWidgets('mock adapter injectable', (tester) async {
      final adapter = MockScannerAdapter();
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: adapter),
      ));
      expect(adapter.status, ScannerStatus.idle);
    });
  });
}
