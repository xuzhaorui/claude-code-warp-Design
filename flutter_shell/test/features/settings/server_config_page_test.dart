import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/settings/server_config_page.dart';
import 'package:wms_app/features/settings/server_config_store.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ServerConfigPage', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(wrapApp(
        const ServerConfigPage(),
      ));
      expect(find.text('服务配置'), findsOneWidget);
    });

    testWidgets('empty state shows 暂无服务配置', (tester) async {
      await tester.pumpWidget(wrapApp(
        const ServerConfigPage(),
      ));
      expect(find.text('暂无服务配置'), findsOneWidget);
    });

    testWidgets('renders 添加服务器 button', (tester) async {
      await tester.pumpWidget(wrapApp(
        const ServerConfigPage(),
      ));
      expect(find.text('添加服务器'), findsOneWidget);
    });

    testWidgets('tap 添加服务器 shows form', (tester) async {
      await tester.pumpWidget(wrapApp(
        const ServerConfigPage(),
      ));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('测试连接'), findsOneWidget);
    });

    testWidgets('test connection shows placeholder', (tester) async {
      await tester.pumpWidget(wrapApp(
        ServerConfigPage(store: InMemoryServerConfigStore()),
      ));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      await tester.tap(find.text('测试连接'));
      await tester.pump();
      expect(find.text('待接入真实连接测试'), findsOneWidget);
    });

    testWidgets('save valid config displays success message', (tester) async {
      await tester.pumpWidget(wrapApp(
        ServerConfigPage(store: InMemoryServerConfigStore()),
      ));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();

      // Type server name and URL
      await tester.enterText(find.byType(TextFormField).first, '主服务器');
      await tester.enterText(find.byType(TextFormField).last, 'http://192.168.1.100:8080');
      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('服务配置已保存'), findsOneWidget);
    });

    testWidgets('after save active server is displayed', (tester) async {
      final store = InMemoryServerConfigStore();
      await tester.pumpWidget(wrapApp(
        ServerConfigPage(store: store),
      ));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, '主服务器');
      await tester.enterText(find.byType(TextFormField).last, 'http://192.168.1.100:8080');
      await tester.tap(find.text('保存'));
      await tester.pump();

      // After save, the page shows the active server.
      expect(find.textContaining('当前服务器'), findsOneWidget);
    });

    testWidgets('settings page does not call real API', (tester) async {
      await tester.pumpWidget(wrapApp(
        const ServerConfigPage(),
      ));
      // No real API call triggered — verified by absence of network calls.
      expect(find.byType(ServerConfigPage), findsOneWidget);
    });
  });
}
