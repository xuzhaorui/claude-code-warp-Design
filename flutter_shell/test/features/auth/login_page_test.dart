import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/api/mock_warehouse_api_client.dart';
import 'package:wms_app/features/auth/login_page.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('LoginPage', () {
    testWidgets('shows active server name and change entry', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          LoginPage(
            apiClient: MockWarehouseApiClient(),
            onLoggedIn: (_) {},
            activeServerName: '主服务器',
            onChangeServer: () {},
          ),
        ),
      );

      expect(find.text('当前使用用户：主服务器'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.text('更换'), findsOneWidget);
    });

    testWidgets('tapping change server entry fires callback', (tester) async {
      bool fired = false;
      await tester.pumpWidget(
        wrapApp(
          LoginPage(
            apiClient: MockWarehouseApiClient(),
            onLoggedIn: (_) {},
            activeServerName: '主服务器',
            onChangeServer: () => fired = true,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '更换'));
      await tester.pump();

      expect(fired, isTrue);
    });
  });
}
