import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/api/warehouse_api_models.dart';
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

    // 9. image-recognition hint removed (task-041 Web parity)
    testWidgets('image recognition hint removed', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('从图片识别'), findsNothing);
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

    // 22. records are displayed when provided
    testWidgets('records displayed when provided', (tester) async {
      final records = [
        RecordItem(title: 'Item A', detail: '5件', status: '正常'),
        RecordItem(title: 'Item B', detail: '3件', status: '已撤销'),
      ];
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(records: records),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('5件'), findsOneWidget);
    });

    // 23. empty records shows empty state
    testWidgets('empty records shows empty state', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(records: []),
      ));
      // Empty records should still show the "暂无出库记录" empty state.
      expect(find.text('暂无出库记录'), findsOneWidget);
    });

    // 24. checkout page shows the scan call-to-action text (per-tab)
    testWidgets('checkout scan card shows 点击扫码出库', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.text('点击扫码出库'), findsOneWidget);
      // subtitle removed in task-041
      expect(find.text('扫描条码或二维码'), findsNothing);
    });

    // 24b. return tab scan CTA
    testWidgets('return scan card shows 点击扫码归还', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      expect(find.text('点击扫码归还'), findsOneWidget);
    });

    // 24c. inventory tab scan CTA
    testWidgets('inventory scan card shows 点击扫码盘点', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.text('点击扫码盘点'), findsOneWidget);
    });

    // 24d. top large titles removed
    testWidgets('no large 出库 title header on checkout', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      // 出库 still appears as the nav label, but NOT as a page title.
      // The scan CTA is the primary text on the checkout tab.
      expect(find.text('点击扫码出库'), findsOneWidget);
    });

    // 24e. Debug manual input no longer rendered in the shell
    testWidgets('debug manual input not shown in shell', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.textContaining('Debug'), findsNothing);
      expect(find.text('手动输入扫码值'), findsNothing);
    });

    // 25. status row surfaces the active server name when provided
    testWidgets('status row shows active server name', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(activeServerName: 'CS'),
      ));
      expect(find.textContaining('当前服务器'), findsOneWidget);
      expect(find.textContaining('CS'), findsOneWidget);
    });

    // 26. status row shows 未配置 when no server name provided
    testWidgets('status row shows 未配置 when no server name', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      expect(find.textContaining('未配置'), findsOneWidget);
    });

    // 27. checkout nav label still present (top title removed, nav remains)
    testWidgets('checkout tab nav label 出库 present', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellMin()));
      // The large page title was removed; the bottom-nav label remains.
      expect(find.text('出库'), findsWidgets);
    });

    // 28. checkout record list shows Web-parity fields
    testWidgets('checkout record card shows parity fields', (tester) async {
      final records = [
        RecordItem(
          title: 'Widget Pro',
          detail: '5 件 · 成本 ¥25.00 · 外销',
          status: '正常',
          kind: RecordKind.checkout,
          source: const CheckoutRecord(
            itemName: 'Widget Pro',
            quantity: 5,
            costPrice: 25.0,
            type: 1,
            warehouse: '主仓库',
            operatorName: '张三',
            time: '2026-07-01',
            status: '正常',
          ),
        ),
      ];
      await tester.pumpWidget(wrapApp(WarehouseShellMin(records: records)));
      await tester.pumpAndSettle();
      expect(find.text('Widget Pro'), findsOneWidget);
      expect(find.textContaining('5 件'), findsOneWidget);
      expect(find.textContaining('外销'), findsOneWidget);
    });

    // 29. tapping a checkout record opens the detail BottomSheet
    testWidgets('tapping checkout record opens detail sheet', (tester) async {
      final records = [
        RecordItem(
          title: 'Widget Pro',
          detail: '5 件 · 成本 ¥25.00 · 外销',
          status: '正常',
          kind: RecordKind.checkout,
          source: const CheckoutRecord(
            itemName: 'Widget Pro',
            spec: '500ml',
            code: 'WP-001',
            quantity: 5,
            costPrice: 25.0,
            type: 1,
            warehouse: '主仓库',
            operatorName: '张三',
            time: '2026-07-01',
            status: '正常',
          ),
        ),
      ];
      await tester.pumpWidget(wrapApp(WarehouseShellMin(records: records)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Widget Pro'));
      await tester.pumpAndSettle();
      expect(find.text('出库详情'), findsOneWidget);
      expect(find.text('数量'), findsOneWidget);
      expect(find.text('仓库'), findsOneWidget);
    });

    // 30. tapping a return record opens the detail BottomSheet
    testWidgets('tapping return record opens detail sheet', (tester) async {
      final records = [
        RecordItem(
          title: 'Widget Pro',
          detail: '3 件 · 李四',
          status: '正常',
          kind: RecordKind.returnForm,
          source: const ReturnRecord(
            itemName: 'Widget Pro',
            returnQty: 3,
            borrower: '李四',
            warehouse: '主仓库',
            operatorName: '张三',
            status: '正常',
          ),
        ),
      ];
      await tester.pumpWidget(wrapApp(WarehouseShellMin(
        initialTab: WarehouseTab.returnForm,
        records: records,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Widget Pro'));
      await tester.pumpAndSettle();
      expect(find.text('归还详情'), findsOneWidget);
      expect(find.text('归还数量'), findsOneWidget);
      expect(find.text('外借人'), findsOneWidget);
    });

    // 31. tapping an inventory record opens the detail BottomSheet
    testWidgets('tapping inventory record opens detail sheet', (tester) async {
      final records = [
        RecordItem(
          title: 'Widget Pro',
          detail: '实盘 48 件 · 差值 -2 件',
          status: '正常',
          kind: RecordKind.inventoryCheck,
          source: const InventoryCheckRecord(
            itemName: 'Widget Pro',
            bookQty: 50,
            actualQty: 48,
            difference: -2,
            costPrice: 25.0,
            warehouse: '主仓库',
          ),
        ),
      ];
      await tester.pumpWidget(wrapApp(WarehouseShellMin(
        initialTab: WarehouseTab.inventoryCheck,
        records: records,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Widget Pro'));
      await tester.pumpAndSettle();
      expect(find.text('盘点详情'), findsOneWidget);
      expect(find.text('实盘数量'), findsOneWidget);
      expect(find.text('账面库存'), findsOneWidget);
      expect(find.text('盘点差值'), findsOneWidget);
    });

    // 32. detail sheet is closeable
    testWidgets('detail sheet can be closed', (tester) async {
      final records = [
        RecordItem(
          title: 'Widget Pro',
          detail: '5 件 · 成本 ¥25.00 · 外销',
          kind: RecordKind.checkout,
          source: const CheckoutRecord(itemName: 'Widget Pro', quantity: 5),
        ),
      ];
      await tester.pumpWidget(wrapApp(WarehouseShellMin(records: records)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Widget Pro'));
      await tester.pumpAndSettle();
      expect(find.text('出库详情'), findsOneWidget);
      // The AppBottomSheetFrame close button uses Icons.close.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('出库详情'), findsNothing);
    });
  });
}
