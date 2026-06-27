import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_button.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme so that
/// AppButton can resolve tokens (AppDesignColors, Theme, etc.).
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('AppButton', () {
    // 1. primary variant renders text
    testWidgets('primary renders text label', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppButton(text: '提交', onPressed: null),
      ));

      expect(find.text('提交'), findsOneWidget);
      // Should be an ElevatedButton (primary uses ElevatedButton).
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    // 2. secondary variant renders text
    testWidgets('secondary renders text label', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppButton(
          text: '取消',
          variant: AppButtonVariant.secondary,
          onPressed: null,
        ),
      ));

      expect(find.text('取消'), findsOneWidget);
      // Should be a FilledButton (secondary uses FilledButton).
      expect(find.byType(FilledButton), findsOneWidget);
    });

    // 3. disabled state — onTap not fired when tapped
    testWidgets('disabled does not fire onTap', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrapApp(
        AppButton(
          text: '提交',
          disabled: true,
          onPressed: () => tapCount++,
        ),
      ));

      await tester.tap(find.text('提交'));
      expect(tapCount, 0);
    });

    // 4. loading state shows a CircularProgressIndicator
    testWidgets('loading shows progress indicator', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppButton(text: '提交', loading: true, onPressed: null),
      ));

      // The CircularProgressIndicator should be present.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The label text should not be visible (replaced by spinner).
      expect(find.text('提交'), findsNothing);
    });

    // 5. loading state — onTap not fired when tapped
    testWidgets('loading does not fire onTap', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrapApp(
        AppButton(
          text: '提交',
          loading: true,
          onPressed: () => tapCount++,
        ),
      ));

      // Tap where the button would be.
      await tester.tap(find.byType(ElevatedButton));
      expect(tapCount, 0);
    });

    // 6. normal state — onTap fires
    testWidgets('onTap fires when tapped', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrapApp(
        AppButton(
          text: '提交',
          onPressed: () => tapCount++,
        ),
      ));

      await tester.tap(find.text('提交'));
      expect(tapCount, 1);

      await tester.tap(find.text('提交'));
      expect(tapCount, 2);
    });

    // 7. icon + text renders both
    testWidgets('icon and text render together', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppButton(
          text: '扫描',
          icon: Icons.qr_code_scanner,
          onPressed: null,
        ),
      ));

      expect(find.text('扫描'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    // 8. long text does not crash
    testWidgets('long text does not crash', (tester) async {
      final longText = '确认出库' * 50; // ~200 characters
      await tester.pumpWidget(wrapApp(
        AppButton(text: longText, onPressed: null),
      ));

      // Widget should survive long text without crash.
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
