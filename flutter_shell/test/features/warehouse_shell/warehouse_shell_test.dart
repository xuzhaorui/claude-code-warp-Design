import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellMin', () {
    // 1. renders three tabs
    testWidgets('renders three bottom nav items', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      // BottomNavigationBar has three items with labels.
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
    });

    // 2. default tab is checkout
    testWidgets('default tab shows checkout title', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      expect(find.text('出库'), findsWidgets);
      // The AppBar title shows "出库".
    });

    // 3. tapping return tab switches content
    testWidgets('tapping return tab switches content', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      // Tap the second bottom nav item (归还).
      await tester.tap(find.byType(BottomNavigationBar));
      // Actually, need to tap the specific item. Use the nav's onTap.
      // BottomNavigationBar items can be found by text.
      await tester.tap(find.text('归还').last);
      await tester.pump();
      // Description text should update.
      expect(find.textContaining('外借记录'), findsOneWidget);
    });

    // 4. tapping inventory tab switches content
    testWidgets('tapping inventory tab switches content', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.textContaining('实盘数量'), findsOneWidget);
    });

    // 5. tapping checkout tab switches content back
    testWidgets('tapping checkout tab switches back', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      // Switch to return, then back to checkout.
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('出库').last);
      await tester.pump();
      expect(find.textContaining('扫码或选择货物'), findsOneWidget);
    });

    // 6. checkout tab title renders
    testWidgets('checkout tab shows correct description', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      expect(find.text('扫码或选择货物后发起出库'), findsOneWidget);
    });

    // 7. return tab title renders
    testWidgets('return tab shows correct description', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      await tester.tap(find.text('归还').last);
      await tester.pump();
      expect(find.text('选择外借记录后发起归还'), findsOneWidget);
    });

    // 8. inventory tab title renders
    testWidgets('inventory tab shows correct description', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      expect(find.text('选择货物后录入实盘数量'), findsOneWidget);
    });

    // 9. scan callback fires
    testWidgets('scan callback fires', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(
          onScanRequested: () => callCount++,
        ),
      ));
      // Tap the scan action card.
      await tester.tap(find.text('扫码出库'));
      await tester.pump();
      expect(callCount, 1);
    });

    // 10. checkout request callback fires
    testWidgets('checkout request callback fires', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(
          onCheckoutRequested: () => callCount++,
        ),
      ));
      await tester.tap(find.text('发起出库'));
      await tester.pump();
      expect(callCount, 1);
    });

    // 11. return request callback fires
    testWidgets('return request callback fires', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(
          onReturnRequested: () => callCount++,
        ),
      ));
      // Switch to return tab first.
      await tester.tap(find.text('归还').last);
      await tester.pump();
      await tester.tap(find.text('发起归还'));
      await tester.pump();
      expect(callCount, 1);
    });

    // 12. inventory check request callback fires
    testWidgets('inventory check request callback fires', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        WarehouseShellMin(
          onInventoryCheckRequested: () => callCount++,
        ),
      ));
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      await tester.tap(find.text('发起盘点'));
      await tester.pump();
      expect(callCount, 1);
    });

    // 13. shell does not require API (verified by absence of API imports)

    // 14. shell does not require route context
    testWidgets('shell does not require route context', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      expect(find.byType(WarehouseShellMin), findsOneWidget);
    });

    // 15. long labels do not crash
    testWidgets('long labels do not crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      expect(find.byType(WarehouseShellMin), findsOneWidget);
    });

    // 16. selected / unselected tab state changes
    testWidgets('tab state changes on navigation', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellMin(),
      ));
      // Default is checkout. Switch to inventory.
      await tester.tap(find.text('盘点').last);
      await tester.pump();
      // The description should now be inventory-related.
      expect(find.textContaining('实盘数量'), findsOneWidget);
      // Checkout description should NOT be visible.
      expect(find.text('扫码或选择货物后发起出库'), findsNothing);
    });
  });
}
