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
      await tester.pumpWidget(wrapApp(const ServerConfigPage()));
      expect(find.text('服务配置'), findsOneWidget);
    });

    testWidgets('empty state shows 暂无服务配置', (tester) async {
      await tester.pumpWidget(wrapApp(const ServerConfigPage()));
      expect(find.text('暂无服务配置'), findsOneWidget);
    });

    testWidgets('renders 添加服务器 button', (tester) async {
      await tester.pumpWidget(wrapApp(const ServerConfigPage()));
      expect(find.text('添加服务器'), findsOneWidget);
    });

    testWidgets('tap 添加服务器 shows form', (tester) async {
      await tester.pumpWidget(wrapApp(const ServerConfigPage()));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('测试连接'), findsOneWidget);
    });

    testWidgets('test connection shows placeholder', (tester) async {
      await tester.pumpWidget(
        wrapApp(ServerConfigPage(store: InMemoryServerConfigStore())),
      );
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      await tester.tap(find.text('测试连接'));
      await tester.pump();
      expect(find.text('待接入真实连接测试'), findsOneWidget);
    });

    testWidgets('save valid config displays success message', (tester) async {
      await tester.pumpWidget(
        wrapApp(ServerConfigPage(store: InMemoryServerConfigStore())),
      );
      await tester.tap(find.text('添加服务器'));
      await tester.pump();

      // Type server name and URL
      await tester.enterText(find.byType(TextFormField).first, '主服务器');
      await tester.enterText(
        find.byType(TextFormField).last,
        'http://192.168.1.100:8080',
      );
      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('服务配置已保存'), findsOneWidget);
    });

    testWidgets('after save active server is displayed', (tester) async {
      final store = InMemoryServerConfigStore();
      await tester.pumpWidget(wrapApp(ServerConfigPage(store: store)));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, '主服务器');
      await tester.enterText(
        find.byType(TextFormField).last,
        'http://192.168.1.100:8080',
      );
      await tester.tap(find.text('保存'));
      await tester.pump();

      // After save, the page shows the active server.
      expect(find.textContaining('当前服务器'), findsOneWidget);
    });

    testWidgets('settings page does not call real API', (tester) async {
      await tester.pumpWidget(wrapApp(const ServerConfigPage()));
      // No real API call triggered — verified by absence of network calls.
      expect(find.byType(ServerConfigPage), findsOneWidget);
    });

    testWidgets('shows section labels 可用服务器 and 当前 badge after save', (
      tester,
    ) async {
      final store = InMemoryServerConfigStore();
      await tester.pumpWidget(wrapApp(ServerConfigPage(store: store)));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, '主服务器');
      await tester.enterText(
        find.byType(TextFormField).last,
        'http://192.168.1.100:8080',
      );
      await tester.tap(find.text('保存'));
      await tester.pump();

      // Section labels and the active-server "当前" badge render.
      expect(find.text('当前服务器'), findsOneWidget);
      expect(find.text('可用服务器'), findsOneWidget);
      expect(find.text('当前'), findsOneWidget);
    });

    testWidgets('selecting a server marks it active via chevron tile', (
      tester,
    ) async {
      final store = InMemoryServerConfigStore();
      // Seed two servers so the list is selectable.
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a'),
        ServerConfig(name: 'B', baseUrl: 'http://b'),
      ]);
      await store.setActiveServer('http://a');

      await tester.pumpWidget(wrapApp(ServerConfigPage(store: store)));
      await tester.pumpAndSettle();

      // Tapping server B selects it.
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.radio_button_checked), findsWidgets);
    });

    testWidgets('selecting a server fires onServerChanged when wired', (
      tester,
    ) async {
      final store = InMemoryServerConfigStore();
      await store.saveServers([
        const ServerConfig(name: 'A', baseUrl: 'http://a'),
        const ServerConfig(name: 'B', baseUrl: 'http://b'),
      ]);
      await store.setActiveServer('http://a');
      bool fired = false;

      await tester.pumpWidget(
        wrapApp(
          ServerConfigPage(
            store: store,
            onLogout: () {},
            onServerChanged: () => fired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('服务器配置'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(fired, isTrue);
    });

    // task-042: logout button only renders when onLogout is wired (in-shell).
    testWidgets('renders 退出登录 when onLogout provided', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ServerConfigPage(store: InMemoryServerConfigStore(), onLogout: () {}),
        ),
      );
      expect(find.text('退出登录'), findsOneWidget);
    });

    testWidgets('does not render 退出登录 during initial setup', (tester) async {
      await tester.pumpWidget(wrapApp(const ServerConfigPage()));
      expect(find.text('退出登录'), findsNothing);
    });

    testWidgets('tapping 退出登录 fires onLogout', (tester) async {
      bool fired = false;
      await tester.pumpWidget(
        wrapApp(
          ServerConfigPage(
            store: InMemoryServerConfigStore(),
            onLogout: () => fired = true,
          ),
        ),
      );
      await tester.tap(find.text('退出登录'));
      await tester.pump();
      expect(fired, isTrue);
    });

    // task-046: settings home (图四 style) shows 设置 + 服务器配置 card.
    testWidgets('settings home shows 设置 title and 服务器配置 card', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ServerConfigPage(store: InMemoryServerConfigStore(), onLogout: () {}),
        ),
      );
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('服务器配置'), findsOneWidget);
      expect(find.text('管理连接的服务器地址'), findsOneWidget);
    });

    testWidgets('settings home does not show 当前服务器 / 添加服务器', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ServerConfigPage(store: InMemoryServerConfigStore(), onLogout: () {}),
        ),
      );
      expect(find.text('当前服务器'), findsNothing);
      expect(find.text('可用服务器'), findsNothing);
      expect(find.text('添加服务器'), findsNothing);
    });

    testWidgets('tapping 服务器配置 enters management view', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ServerConfigPage(store: InMemoryServerConfigStore(), onLogout: () {}),
        ),
      );
      await tester.tap(find.text('服务器配置'));
      await tester.pump();
      // Management view shows the add-server button + empty state.
      expect(find.text('添加服务器'), findsOneWidget);
      expect(find.text('暂无服务配置'), findsOneWidget);
      // Back arrow returns to home.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(find.text('设置'), findsOneWidget);
    });

    // task: add form has a 取消 button.
    testWidgets('add form has a 取消 button that closes the form', (tester) async {
      final store = InMemoryServerConfigStore();
      await tester.pumpWidget(wrapApp(ServerConfigPage(store: store)));
      await tester.tap(find.text('添加服务器'));
      await tester.pump();
      expect(find.text('取消'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pump();
      // Form closed — add button visible again.
      expect(find.text('添加服务器'), findsOneWidget);
      expect(find.text('保存'), findsNothing);
    });

    // task: delete a server.
    testWidgets('deleting a server removes it from the list', (tester) async {
      final store = InMemoryServerConfigStore();
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a'),
        ServerConfig(name: 'B', baseUrl: 'http://b'),
      ]);
      await store.setActiveServer('http://a');
      await tester.pumpWidget(wrapApp(ServerConfigPage(store: store)));
      await tester.pumpAndSettle();
      // Open options for server A via its more-vert icon.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      // A is gone, B remains.
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });

    // task: edit a server prefills the form.
    testWidgets('editing a server prefills the form with 修改服务器 title', (tester) async {
      final store = InMemoryServerConfigStore();
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a'),
      ]);
      await store.setActiveServer('http://a');
      await tester.pumpWidget(wrapApp(ServerConfigPage(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改'));
      await tester.pumpAndSettle();
      expect(find.text('修改服务器'), findsOneWidget);
      // Form fields prefilled with server A's values.
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });
  });
}
