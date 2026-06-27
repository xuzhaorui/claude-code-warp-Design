import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_segmented_control.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme.
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

/// Enum used to verify enum-value support.
enum _TestMethod { sale, borrow }

void main() {
  group('AppSegmentedControl<String>', () {
    // 1. renders all options
    testWidgets('renders all options', (tester) async {
      await tester.pumpWidget(wrapApp(
        _control(
          options: const [
            AppSegmentedOption(value: 'a', label: '选项一'),
            AppSegmentedOption(value: 'b', label: '选项二'),
            AppSegmentedOption(value: 'c', label: '选项三'),
          ],
          selectedValue: 'a',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('选项一'), findsOneWidget);
      expect(find.text('选项二'), findsOneWidget);
      expect(find.text('选项三'), findsOneWidget);
    });

    // 2. selected option renders with correct text
    testWidgets('selected option is present', (tester) async {
      await tester.pumpWidget(wrapApp(
        _control(
          options: const [
            AppSegmentedOption(value: 'a', label: '已选'),
            AppSegmentedOption(value: 'b', label: '未选'),
          ],
          selectedValue: 'a',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('已选'), findsOneWidget);
      expect(find.text('未选'), findsOneWidget);
    });

    // 3. tapping unselected option fires onChanged
    testWidgets('tapping unselected option fires onChanged', (tester) async {
      String? captured;
      await tester.pumpWidget(wrapApp(
        _control(
          options: const [
            AppSegmentedOption(value: 'a', label: 'A'),
            AppSegmentedOption(value: 'b', label: 'B'),
          ],
          selectedValue: 'a',
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('B'));
      expect(captured, 'b');
    });

    // 4. tapping already-selected option does NOT fire onChanged
    testWidgets('tapping selected option does not fire onChanged',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        _control(
          options: const [
            AppSegmentedOption(value: 'a', label: 'A'),
            AppSegmentedOption(value: 'b', label: 'B'),
          ],
          selectedValue: 'a',
          onChanged: (_) => callCount++,
        ),
      ));
      await tester.tap(find.text('A'));
      expect(callCount, 0);
    });

    // 5. disabled state prevents onChanged
    testWidgets('disabled state prevents onChanged', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(wrapApp(
        _control(
          options: const [
            AppSegmentedOption(value: 'a', label: 'A'),
            AppSegmentedOption(value: 'b', label: 'B'),
          ],
          selectedValue: 'a',
          onChanged: (_) => callCount++,
          disabled: true,
        ),
      ));
      await tester.tap(find.text('B'));
      expect(callCount, 0);
    });

    // 6. compact mode renders without crash
    testWidgets('compact mode renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        _control(
          options: const [
            AppSegmentedOption(value: 'a', label: 'A'),
            AppSegmentedOption(value: 'b', label: 'B'),
          ],
          selectedValue: 'a',
          onChanged: (_) {},
          compact: true,
        ),
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    // 7. long label does not crash
    testWidgets('long label does not crash', (tester) async {
      final longLabel = '这是一个非常长的分段控件标签文字' * 5;
      await tester.pumpWidget(wrapApp(
        _control(
          options: [
            AppSegmentedOption(value: 'a', label: longLabel),
            const AppSegmentedOption(value: 'b', label: '短标签'),
          ],
          selectedValue: 'a',
          onChanged: (_) {},
        ),
      ));
      // Verify the widget is rendered by checking its container structure.
      // (byType doesn't resolve generic types at runtime due to erasure.)
      expect(find.text('短标签'), findsOneWidget);
    });
  });

  group('AppSegmentedControl<enum>', () {
    // 8. supports enum values
    testWidgets('supports enum values', (tester) async {
      _TestMethod? captured;
      await tester.pumpWidget(wrapApp(
        _controlEnum(
          options: const [
            AppSegmentedOption(value: _TestMethod.sale, label: '外销'),
            AppSegmentedOption(value: _TestMethod.borrow, label: '外借'),
          ],
          selectedValue: _TestMethod.sale,
          onChanged: (v) => captured = v,
        ),
      ));
      await tester.tap(find.text('外借'));
      expect(captured, _TestMethod.borrow);
    });
  });

  // 9. supports string values (implicitly covered by tests 1-7)

  // 10. empty options renders safely (not crashing)
  testWidgets('empty options renders safely (no crash)', (tester) async {
    await tester.pumpWidget(wrapApp(
      AppSegmentedControl<String>(
        options: const [],
        selectedValue: '',
        onChanged: _emptyOnChanged,
      ),
    ));
    // Should not crash — empty options just render SizedBox.shrink().
    // Verify by checking the SizedBox is rendered (byType finds SizedBox
    // regardless of generic erasure).
    expect(find.byType(SizedBox), findsOneWidget);
  });
}

// --- Helpers for type inference ---

void _emptyOnChanged(String _) {}

Widget _control({
  required List<AppSegmentedOption<String>> options,
  required String selectedValue,
  required ValueChanged<String> onChanged,
  bool disabled = false,
  bool compact = false,
}) {
  return AppSegmentedControl<String>(
    options: options,
    selectedValue: selectedValue,
    onChanged: onChanged,
    disabled: disabled,
    compact: compact,
  );
}

Widget _controlEnum({
  required List<AppSegmentedOption<_TestMethod>> options,
  required _TestMethod selectedValue,
  required ValueChanged<_TestMethod> onChanged,
}) {
  return AppSegmentedControl<_TestMethod>(
    options: options,
    selectedValue: selectedValue,
    onChanged: onChanged,
  );
}
