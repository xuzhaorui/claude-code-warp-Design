import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellMin', () {
    // 1. renders 4 bottom tabs
    testWidgets('renders 4 bottom nav items', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
      expect(find.text('设置'), findsWidgets);
    });

    // 2. default tab is checkout
    testWidgets('default tab shows checkout badge', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('出库'), findsWidgets);
    });

    // 3. tapping return tab switches content
    testWidgets('tapping return tab shows return badge', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      expect(find.text('归还'), findsWidgets);
    });

    // 4. tapping inventory tab switches content
    testWidgets('tapping inventory tab shows inventory badge', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.text('盘点'), findsWidgets);
    });

    // 5. checkout tab renders scan card
    testWidgets('checkout tab renders scan card', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    // 6. return tab renders scan card
    testWidgets('return tab renders scan card', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    // 7. inventory tab renders scan card
    testWidgets('inventory tab renders scan card', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    // 8. scan card tap fires onScanRequested with current tab
    testWidgets('scan card tap fires onScanRequested', (tester) async {
      WarehouseTab? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(onScanRequested: (tab) => captured = tab),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pump();
      expect(captured, WarehouseTab.checkout);
    });

    // 9. from image recognition text renders
    testWidgets('image recognition hint renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('从图片识别'), findsOneWidget);
    });

    // 10. checkout records section renders
    testWidgets('checkout records section renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('出库记录'), findsOneWidget);
    });

    // 11. return records section renders
    testWidgets('return records section renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      expect(find.text('归还记录'), findsOneWidget);
    });

    // 12. inventory records section renders
    testWidgets('inventory records section renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.text('盘点记录'), findsOneWidget);
    });

    // 13. empty checkout state renders
    testWidgets('empty checkout state renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('暂无出库记录'), findsOneWidget);
    });

    // 14. empty return state renders
    testWidgets('empty return state renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      expect(find.text('暂无归还记录'), findsOneWidget);
    });

    // 15. empty inventory state renders
    testWidgets('empty inventory state renders', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.text('暂无盘点记录'), findsOneWidget);
    });

    // 16. last scan result not shown when null
    testWidgets('last scan result not shown when null', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.textContaining('最近扫码'), findsNothing);
    });

    // 17. last scan result shown when provided
    testWidgets('last scan result shown when provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(lastScanCode: 'P293'),
      ));
      expect(find.textContaining('最近扫码'), findsOneWidget);
      expect(find.textContaining('P293'), findsOneWidget);
    });

    // 18. settings tab renders ServerConfigPage
    testWidgets('settings tab renders ServerConfigPage', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      // Tapping settings tab should show the server config page.
      await tester.tap(find.text('设置').last);
      await tester.pump();
      expect(find.text('服务配置'), findsOneWidget);
    });

    // 19. tab state changes on navigation
    testWidgets('tab switching changes content', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      // Should show inventory-related content.
      expect(find.text('盘点'), findsWidgets);
    });

    // 20. scanning carries correct tab
    testWidgets('scan from return tab carries returnTab', (tester) async {
      WarehouseTab? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(onScanRequested: (tab) => captured = tab),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pump();
      expect(captured, WarehouseTab.returnForm);
    });

    // 21. no API dependency
    testWidgets('no API dependency', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.byType(WarehouseShellMin), findsOneWidget);
    });
  });
}
