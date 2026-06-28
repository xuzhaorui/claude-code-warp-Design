import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/main.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseApp main entrypoint', () {
    testWidgets('WarehouseApp renders native shell root', (tester) async {
      await tester.pumpWidget(const WarehouseApp());
      // The app should mount WarehouseShellScannerEntry, which mounts
      // WarehouseShellFormWiring → WarehouseShellMin.  Verify at least one
      // tab label from the native shell is visible.
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
    });

    testWidgets('WarehouseApp does not contain WebShellPage text', (tester) async {
      await tester.pumpWidget(const WarehouseApp());
      // WebShellPage showed WebView loading localhost — none of that text
      // should appear in the native shell.
      expect(find.text('WebShell'), findsNothing);
      // The native shell shows '扫码出库' instead.
      expect(find.text('扫码出库'), findsWidgets);
    });

    testWidgets('native shell contains checkout tab scan entry', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // The checkout tab should show a "扫码出库" action card.
      expect(find.text('扫码出库'), findsOneWidget);
    });

    testWidgets('native shell contains form entry button', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // The form entry button should be visible.
      expect(find.text('发起出库'), findsOneWidget);
    });

    testWidgets('switching tabs shows different scan labels', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // Default tab is checkout — shows "扫码出库".
      expect(find.text('扫码出库'), findsOneWidget);

      // Tap the return tab (index 1 in BottomNavigationBar).
      await tester.tap(find.byIcon(Icons.replay));
      await tester.pumpAndSettle();
      expect(find.text('扫码归还'), findsOneWidget);

      // Tap the inventory tab (index 2).
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      expect(find.text('扫码盘点'), findsOneWidget);
    });

    testWidgets('native shell has scan icon', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // The qr_code_scanner icon should exist.
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });
  });
}
