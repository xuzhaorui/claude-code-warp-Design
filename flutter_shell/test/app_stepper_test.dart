import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_stepper.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme so that
/// AppStepper can resolve tokens (AppDesignColors, AppTextStyles, etc.).
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('AppStepper', () {
    // 1. Renders label and value
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppStepper(
          value: 5,
          onChanged: null,
          label: '数量',
        ),
      ));
      expect(find.text('数量'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    // 2. Renders helperText when provided
    testWidgets('renders helperText when provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppStepper(
          value: 5,
          onChanged: null,
          helperText: '请选择出库数量',
        ),
      ));
      expect(find.text('请选择出库数量'), findsOneWidget);
    });

    // 3. Increment button increases value
    testWidgets('increment button increases value', (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 5,
          onChanged: (v) => captured = v,
        ),
      ));
      // Tap the "+" button — find it by text.
      await tester.tap(find.text('+'));
      expect(captured, 6);
    });

    // 4. Decrement button decreases value
    testWidgets('decrement button decreases value', (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 5,
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('−'));
      expect(captured, 4);
    });

    // 5. Decrement disabled at min
    testWidgets('decrement disabled when value equals min', (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 1,
          min: 1,
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('−'));
      // Should NOT have fired — value === min.
      expect(captured, isNull);
    });

    // 6. Increment disabled at max
    testWidgets('increment disabled when value equals max', (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 10,
          max: 10,
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('+'));
      // Should NOT have fired — value === max.
      expect(captured, isNull);
    });

    // 7. Disabled state prevents changes
    testWidgets('disabled state prevents both increment and decrement',
        (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 5,
          min: 1,
          max: 10,
          disabled: true,
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('+'));
      expect(captured, isNull);
      await tester.tap(find.text('−'));
      expect(captured, isNull);
    });

    // 8. Custom step works
    testWidgets('custom step increments by step amount', (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 5,
          step: 5,
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('+'));
      expect(captured, 10);
    });

    // 9. Long label/helperText does not crash
    testWidgets('long label and helperText do not crash', (tester) async {
      final longLabel = '这是一个非常长的步进器标签' * 10;
      final longHelper = '这是一段非常长的辅助说明文字' * 10;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 5,
          label: longLabel,
          helperText: longHelper,
          onChanged: null,
        ),
      ));
      expect(find.byType(AppStepper), findsOneWidget);
    });

    // 10. Value outside min/max tolerance
    // Decision: clamp at interaction time rather than assert.
    // Reason: the parent controls the displayed value. If the parent passes
    // a value outside bounds, it's the parent's responsibility — but the
    // component should not crash or misbehave.
    testWidgets('value below min can still increment into range',
        (tester) async {
      num? captured;
      await tester.pumpWidget(wrapApp(
        AppStepper(
          value: 0, // below min (default 1)
          onChanged: (v) => captured = v,
        ),
      ));
      // Increment should work: 0 + 1 = 1, which is within [1, 9999]
      await tester.tap(find.text('+'));
      expect(captured, 1);
    });
  });
}
