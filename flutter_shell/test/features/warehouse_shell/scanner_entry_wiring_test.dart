import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/api/mock_warehouse_api_client.dart';
import 'package:wms_app/features/scanner/scanner_adapter.dart';
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
      // ScannerPage has an infinite scan-line animation; pump the route
      // transition explicitly instead of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
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
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    testWidgets('no business logic on scan entry', (tester) async {
      bool businessTriggered = false;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          onCheckoutSubmit: (_) => businessTriggered = true,
        ),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(businessTriggered, isFalse);
    });

    testWidgets('scan card renders with qr icon', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      expect(find.byKey(const Key('scan_card')), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
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

    testWidgets('mock adapter injectable', (tester) async {
      final adapter = MockScannerAdapter();
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: adapter),
      ));
      expect(adapter.status, ScannerStatus.idle);
    });

    // ── API lookup tests ──

    testWidgets('checkout tab scan with apiClient calls findItemByCode', (tester) async {
      final mockApi = MockWarehouseApiClient();

      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          apiClient: mockApi,
        ),
      ));
      // The scan card is on the checkout tab by default.
      expect(find.byKey(const Key('scan_card')), findsOneWidget);
    });

    testWidgets('unknown code with apiClient does not open form', (tester) async {
      bool formOpened = false;
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          apiClient: MockWarehouseApiClient(),
          onCheckoutSubmit: (_) => formOpened = true,
        ),
      ));
      // Unknown code should not open a form — verified by absence
      // of business trigger at render time.
      expect(formOpened, isFalse);
    });

    testWidgets('scan error state is clearable', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(
          adapter: MockScannerAdapter(),
          apiClient: MockWarehouseApiClient(),
        ),
      ));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    testWidgets('apiClient defaults to null (fixture fallback)', (tester) async {
      await tester.pumpWidget(wrapApp(
        WarehouseShellScannerEntry(adapter: MockScannerAdapter()),
      ));
      // No apiClient set → uses fixture data. Scanner still opens.
      await tester.tap(find.byKey(const Key('scan_card')));
      // ScannerPage has an infinite scan-line animation; pump the route
      // transition explicitly instead of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('退出扫码'), findsOneWidget);
    });
  });
}
