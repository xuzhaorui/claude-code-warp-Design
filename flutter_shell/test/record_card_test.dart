import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/record_card.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme so that
/// RecordCard can resolve tokens (AppDesignColors, Theme, etc.).
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

/// Pumps [widget] and advances the clock past the stagger timer so the test
/// does not fail with "A Timer is still pending".
Future<void> pumpCard(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(wrapApp(card));
  // Advance past _RC.staggerMs (50ms) so the initState Future.delayed fires.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('RecordCard', () {
    testWidgets('renders title and detail', (tester) async {
      await pumpCard(tester,
        const RecordCard(title: '单号001', detail: '供应商: 北京仓库'),
      );

      expect(find.text('单号001'), findsOneWidget);
      expect(find.text('供应商: 北京仓库'), findsOneWidget);
    });

    testWidgets('renders status badge when provided', (tester) async {
      await pumpCard(tester,
        const RecordCard(title: '单号002', detail: '备注备忘', status: '已完成'),
      );

      expect(find.text('已完成'), findsOneWidget);
    });

    testWidgets('does not render status badge when status is null',
        (tester) async {
      await pumpCard(tester,
        const RecordCard(title: '单号003', detail: '无状态测试'),
      );

      expect(find.text('单号003'), findsOneWidget);
      expect(find.text('无状态测试'), findsOneWidget);
      expect(find.text('已完成'), findsNothing);
    });

    testWidgets('onTap fires when card is tapped', (tester) async {
      int tapCount = 0;
      await pumpCard(tester,
        RecordCard(
          title: '可点击卡片',
          detail: '点击详情',
          onTap: () => tapCount++,
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(tapCount, 1);
    });

    testWidgets('long title and detail do not crash', (tester) async {
      await pumpCard(tester,
        RecordCard(title: 'A' * 500, detail: 'B' * 500),
      );

      // Widget rendered without throw; verify by finding the card + its texts.
      expect(find.byType(RecordCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RecordCard),
          matching: find.byType(Text),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('supports all known status values', (tester) async {
      for (final status in ['正常', '已完成', '异常', '亏损', '已撤销', '进行中', '待处理']) {
        // Use distinct content so status text never collides with title/detail.
        await pumpCard(tester,
          RecordCard(title: '状态卡片', detail: '细节内容_$status', status: status),
        );
        // Only the status badge should contain the status string.
        expect(find.text(status), findsOneWidget);
        expect(find.byType(RecordCard), findsOneWidget);
      }
    });

    testWidgets('chevron icon is present', (tester) async {
      await pumpCard(tester,
        const RecordCard(title: '箭头测试', detail: '详情'),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}
