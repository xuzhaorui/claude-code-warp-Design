import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/components/app_form_section.dart';
import 'package:wms_app/design/app_theme.dart';

/// Helper: wraps [child] in a MaterialApp with the warehouse theme.
Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  group('AppFormSection', () {
    // 1. renders title
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppFormSection(
          title: '出库信息',
          child: Text('表单内容'),
        ),
      ));
      expect(find.text('出库信息'), findsOneWidget);
    });

    // 2. renders subtitle when provided
    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppFormSection(
          title: '出库信息',
          subtitle: '请填写出库数量',
          child: Text('表单内容'),
        ),
      ));
      expect(find.text('请填写出库数量'), findsOneWidget);
    });

    // 3. does not render subtitle when null
    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppFormSection(
          title: '出库信息',
          child: Text('表单内容'),
        ),
      ));
      expect(find.text('请填写出库数量'), findsNothing);
    });

    // 4. renders child content
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppFormSection(
          title: '出库信息',
          child: Text('自定义内容'),
        ),
      ));
      expect(find.text('自定义内容'), findsOneWidget);
    });

    // 5. renders actions
    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(wrapApp(
        AppFormSection(
          title: '出库信息',
          actions: const [Text('操作一'), Text('操作二')],
          child: const Text('表单内容'),
        ),
      ));
      expect(find.text('操作一'), findsOneWidget);
      expect(find.text('操作二'), findsOneWidget);
    });

    // 6. renders errorText
    testWidgets('renders errorText', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppFormSection(
          title: '出库信息',
          errorText: '数量不能为空',
          child: Text('表单内容'),
        ),
      ));
      expect(find.text('数量不能为空'), findsOneWidget);
    });

    // 7. renders leading widget
    testWidgets('renders leading widget', (tester) async {
      await tester.pumpWidget(wrapApp(
        AppFormSection(
          title: '出库信息',
          leading: const Icon(Icons.info_outline),
          child: const Text('表单内容'),
        ),
      ));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    // 8. renders trailing widget
    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(wrapApp(
        AppFormSection(
          title: '出库信息',
          trailing: const Text('￥100.00'),
          child: const Text('表单内容'),
        ),
      ));
      expect(find.text('￥100.00'), findsOneWidget);
    });

    // 9. renders footer
    testWidgets('renders footer', (tester) async {
      await tester.pumpWidget(wrapApp(
        AppFormSection(
          title: '出库信息',
          footer: const Text('成本单价：￥50.00'),
          child: const Text('表单内容'),
        ),
      ));
      expect(find.text('成本单价：￥50.00'), findsOneWidget);
    });

    // 10. disabled state renders without breaking child
    testWidgets('disabled state renders without breaking child',
        (tester) async {
      await tester.pumpWidget(wrapApp(
        AppFormSection(
          title: '出库信息',
          disabled: true,
          child: const Text('表单内容'),
        ),
      ));
      expect(find.text('出库信息'), findsOneWidget);
      expect(find.text('表单内容'), findsOneWidget);
    });

    // 11. compact mode renders without crash
    testWidgets('compact mode renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AppFormSection(
          title: '出库信息',
          subtitle: '请填写信息',
          compact: true,
          child: Text('表单内容'),
        ),
      ));
      expect(find.text('出库信息'), findsOneWidget);
      // Subtitle should not be visible in compact mode.
      expect(find.text('请填写信息'), findsNothing);
    });

    // 12. long title/subtitle/errorText does not crash
    testWidgets('long title subtitle and errorText do not crash',
        (tester) async {
      final longTitle = '这是一个非常长的表单区块标题' * 10;
      final longSubtitle = '这是一段非常长的副标题说明文字' * 10;
      final longError = '这是一个非常长的错误提示信息' * 10;
      await tester.pumpWidget(wrapApp(
        AppFormSection(
          title: longTitle,
          subtitle: longSubtitle,
          errorText: longError,
          child: const Text('表单内容'),
        ),
      ));
      expect(find.byType(AppFormSection), findsOneWidget);
    });
  });
}
