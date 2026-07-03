import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_form_wiring.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellFormWiring', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.byType(WarehouseShellFormWiring), findsOneWidget);
    });

    testWidgets('renders 4 bottom tabs', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
      expect(find.text('设置'), findsWidgets);
    });

    testWidgets('default tab is checkout', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.text('出库'), findsWidgets);
    });

    testWidgets('lastScanCode no longer surfaces a reminder card', (tester) async {
      // task-042: the "最近扫码" reminder was removed; lastScanCode is no
      // longer rendered as a card in the shell.
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(lastScanCode: 'P293'),
      ));
      expect(find.textContaining('最近扫码'), findsNothing);
    });

    testWidgets('scan callback fires with tab', (tester) async {
      WarehouseTab? captured;
      await tester.pumpWidget(wrapApp(
        WarehouseShellFormWiring(
          onScanRequested: (tab) => captured = tab,
        ),
      ));
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pump();
      expect(captured, WarehouseTab.checkout);
    });

    testWidgets('settings tab renders server config', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      await tester.tap(find.text('设置').last);
      await tester.pump();
      expect(find.text('服务配置'), findsOneWidget);
    });

    testWidgets('no API dependency', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.byType(WarehouseShellFormWiring), findsOneWidget);
    });

    // task: scan errors are now shown via SnackBar toast (in the scanner
    // entry layer), not as an inline card in the shell.  The shell renders
    // only records / empty state — no inline error text.
    testWidgets('no inline scan error card in shell', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.text('未找到该物资'), findsNothing);
    });
  });
}
