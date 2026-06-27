import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_select_card.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme so that
/// AppSelectCard can resolve tokens (AppDesignColors, Theme, etc.).
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('AppSelectCard', () {
    // 1. Renders title and subtitle
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppSelectCard(
          title: '服务器一',
          subtitle: '192.168.1.100',
        ),
      ));
      expect(find.text('服务器一'), findsOneWidget);
      expect(find.text('192.168.1.100'), findsOneWidget);
    });

    // 2. Selected state renders check icon indicator
    testWidgets('selected state renders check icon', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppSelectCard(
          title: '服务器一',
          selected: true,
        ),
      ));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // 3. Unselected state does not render check icon
    testWidgets('unselected state does not render check icon',
        (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppSelectCard(
          title: '服务器一',
          selected: false,
        ),
      ));
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    // 4. Disabled state does not fire onTap
    testWidgets('disabled state does not fire onTap', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrapApp(
        AppSelectCard(
          title: '服务器一',
          disabled: true,
          onTap: () => tapCount++,
        ),
      ));
      await tester.tap(find.text('服务器一'));
      expect(tapCount, 0);
    });

    // 5. Enabled state fires onTap
    testWidgets('enabled state fires onTap', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrapApp(
        AppSelectCard(
          title: '服务器一',
          onTap: () => tapCount++,
        ),
      ));
      await tester.tap(find.text('服务器一'));
      expect(tapCount, 1);

      await tester.tap(find.text('服务器一'));
      expect(tapCount, 2);
    });

    // 6. Error state renders with error-styled border
    testWidgets('error state renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppSelectCard(
          title: '服务器一',
          error: true,
        ),
      ));
      // Card should still render title with error border applied.
      expect(find.text('服务器一'), findsOneWidget);
    });

    // 7. Leading icon renders
    testWidgets('leading icon renders', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppSelectCard(
          title: '服务器一',
          leadingIcon: Icons.dns,
        ),
      ));
      expect(find.byIcon(Icons.dns), findsOneWidget);
    });

    // 8. Custom trailing widget renders instead of default check
    testWidgets('custom trailing renders', (tester) async {
      await tester.pumpWidget(wrapApp(
        AppSelectCard(
          title: '服务器一',
          trailing: const Text('自定义尾部'),
        ),
      ));
      expect(find.text('自定义尾部'), findsOneWidget);
      // Default check icon should not appear.
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    // 9. Long text does not crash
    testWidgets('long text does not collapse', (tester) async {
      final longTitle = '这是一个非常长的服务器名称' * 20;
      final longSubtitle = '这是一个非常长的服务器地址描述' * 20;
      await tester.pumpWidget(wrapApp(
        AppSelectCard(
          title: longTitle,
          subtitle: longSubtitle,
        ),
      ));
      expect(find.byType(AppSelectCard), findsOneWidget);
    });

    // 10. Compact mode renders without crash
    testWidgets('compact mode renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppSelectCard(
          title: '服务器一',
          subtitle: '192.168.1.100',
          compact: true,
        ),
      ));
      expect(find.text('服务器一'), findsOneWidget);
      // Subtitle is not shown in compact mode.
      expect(find.text('192.168.1.100'), findsNothing);
    });
  });
}
