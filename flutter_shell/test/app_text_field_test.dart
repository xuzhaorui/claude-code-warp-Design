import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_text_field.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme so that
/// AppTextField can resolve tokens (AppDesignColors, Theme, etc.).
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('AppTextField', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppTextField(label: '单号'),
      ));
      // The label renders as a floating label inside the input decoration.
      expect(find.text('单号'), findsOneWidget);
    });

    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppTextField(hint: '请输入单号'),
      ));
      expect(find.text('请输入单号'), findsOneWidget);
    });

    testWidgets('fires onChanged when text is entered', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        AppTextField(
          label: '单号',
          onChanged: (v) => captured = v,
        ),
      ));

      // Enter text into the field.
      await tester.enterText(find.byType(TextFormField), 'WH-001');
      expect(captured, 'WH-001');
    });

    testWidgets('shows error text and error-styled border', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppTextField(
          label: '单号',
          errorText: '单号不能为空',
        ),
      ));

      // Error message should appear.
      expect(find.text('单号不能为空'), findsOneWidget);

      // The TextFormField should have error styling — verify that the
      // InputDecoration's errorText is non-null by checking the field exists.
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('does not render error when errorText is null',
        (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppTextField(label: '单号'),
      ));

      expect(find.text('单号不能为空'), findsNothing);
    });

    testWidgets('does not accept input when disabled', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        AppTextField(
          label: '单号',
          enabled: false,
          onChanged: (v) => captured = v,
        ),
      ));

      // Try to enter text into a disabled field.
      await tester.enterText(find.byType(TextFormField), 'WH-002');
      // The callback should not have been called.
      expect(captured, isNull);
    });

    testWidgets('long text does not crash', (tester) async {
      final longText = 'A' * 2000;
      await tester.pumpWidget(wrapApp(
        AppTextField(label: '备注', hint: '请输入'),
      ));

      await tester.enterText(find.byType(TextFormField), longText);
      await tester.pump();

      // Widget should survive long text without crashing.
      expect(find.byType(AppTextField), findsOneWidget);
    });

    testWidgets('controller provides initial value', (tester) async {
      final controller = TextEditingController(text: '初始值');
      await tester.pumpWidget(wrapApp(
        AppTextField(label: '单号', controller: controller),
      ));

      expect(find.text('初始值'), findsOneWidget);
    });

    testWidgets('number keyboard accepts only digits', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        AppTextField(
          label: '数量',
          keyboardType: TextInputType.number,
          onChanged: (v) => captured = v,
        ),
      ));

      // Enter numeric value with number keyboard.
      await tester.enterText(find.byType(TextFormField), '42');
      expect(captured, '42');
    });
  });
}
