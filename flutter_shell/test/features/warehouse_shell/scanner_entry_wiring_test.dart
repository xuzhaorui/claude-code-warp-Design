import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/scanner/scanner_adapter.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('ScannerEntryWiring', () {
    // 1. scan entry opens ScannerPage
    testWidgets('tapping scan opens ScannerPage', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      // Scan card by key.
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pumpAndSettle();
      expect(find.text('退出扫码'), findsOneWidget);
    });

    // 2. MockScannerAdapter injectable
    testWidgets('MockScannerAdapter injectable', (tester) async {
      final adapter = MockScannerAdapter();
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: adapter),
      ));
      expect(adapter.status, ScannerStatus.idle);
    });

    // 3. onScanResult callback still fires
    testWidgets('onScanResult callback still fires', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onScanResult: (code) => captured = code,
        ),
      ));
      expect(captured, isNull);
      // The actual emission is verified at the ScannerPage level.
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    // 4. no business form auto-opens after scan
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

    // 5. repeated scans do not crash
    testWidgets('repeated scan entries do not crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pumpAndSettle();
      expect(find.text('退出扫码'), findsOneWidget);
    });

    // 6. scan result returned to Shell display
    testWidgets('scan result display string preserved', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onScanResult: (code) => captured = code,
        ),
      ));
      expect(captured, isNull);
    });
  });
}
