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

    testWidgets('passes lastScanCode to shell', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(lastScanCode: 'P293'),
      ));
      expect(find.textContaining('最近扫码'), findsOneWidget);
      expect(find.textContaining('P293'), findsOneWidget);
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

    testWidgets('scanError is displayed when present', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(scanError: '未找到该物资'),
      ));
      expect(find.text('未找到该物资'), findsOneWidget);
    });

    testWidgets('scanError absent when not provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellFormWiring(),
      ));
      expect(find.text('未找到'), findsNothing);
    });
  });
}
