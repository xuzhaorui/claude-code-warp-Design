import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wms_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WarehouseApp session flow', () {
    testWidgets('switching active server clears session and returns to login', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'wms.serverConfigs': jsonEncode([
          {'name': 'A', 'baseUrl': 'http://a'},
          {'name': 'B', 'baseUrl': 'http://b'},
        ]),
        'wms.activeServerBaseUrl': 'http://a',
        'wms.loggedIn': true,
        'wms.sessionUsername': '张三',
        'wms.sessionCookie': 'JSESSIONID=old',
      });

      await tester.pumpWidget(const WarehouseApp());
      await tester.pumpAndSettle();

      expect(find.text('当前用户：A'), findsOneWidget);

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('服务器配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(find.text('登录'), findsOneWidget);
      expect(find.text('当前使用用户：B'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('wms.loggedIn'), isFalse);
      expect(prefs.getString('wms.sessionUsername'), isNull);
    });
  });
}
