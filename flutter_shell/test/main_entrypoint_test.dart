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
      // The native shell shows tab labels and scan icon.
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    testWidgets('native shell contains scan entry', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // The checkout tab should show a scan card with qr icon.
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('native shell contains scan card', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // The scan card with QR icon should be visible.
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.byKey(const Key('scan_card')), findsOneWidget);
    });

    testWidgets('switching tabs shows different content', (tester) async {
      await tester.pumpWidget(wrapApp(
        const WarehouseShellScannerEntry(),
      ));
      // Default tab is checkout — shows the scan card.
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
      expect(find.text('出库记录'), findsOneWidget);

      // Tap the return tab.
      await tester.tap(find.byIcon(Icons.replay));
      await tester.pumpAndSettle();
      expect(find.text('归还记录'), findsOneWidget);

      // Tap the inventory tab.
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      expect(find.text('盘点记录'), findsOneWidget);
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
