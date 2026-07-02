import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/design/app_theme.dart';
import 'package:wms_app/features/api/warehouse_api_client.dart';
import 'package:wms_app/features/api/warehouse_api_models.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';
import 'package:wms_app/features/scanner/scanner_adapter.dart';
import 'package:wms_app/features/warehouse_shell/warehouse_shell_scanner_entry.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: child);
}

void main() {
  group('WarehouseShellScannerEntry', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(wrapApp(const WarehouseShellScannerEntry()));
      expect(find.byType(WarehouseShellScannerEntry), findsOneWidget);
    });

    testWidgets('renders scan card with qr icon', (tester) async {
      await tester.pumpWidget(
        wrapApp(WarehouseShellScannerEntry(adapter: MockScannerAdapter())),
      );
      expect(find.byKey(const Key('scan_card')), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    testWidgets('tapping scan card opens ScannerPage', (tester) async {
      await tester.pumpWidget(
        wrapApp(WarehouseShellScannerEntry(adapter: MockScannerAdapter())),
      );
      await tester.tap(find.byKey(const Key('scan_card')));
      await tester.pumpAndSettle();
      expect(find.text('退出扫码'), findsOneWidget);
    });

    testWidgets('mock adapter injectable', (tester) async {
      final adapter = MockScannerAdapter();
      await tester.pumpWidget(
        wrapApp(WarehouseShellScannerEntry(adapter: adapter)),
      );
      expect(adapter.status, ScannerStatus.idle);
    });

    testWidgets('renders 4 bottom tabs', (tester) async {
      await tester.pumpWidget(
        wrapApp(WarehouseShellScannerEntry(adapter: MockScannerAdapter())),
      );
      expect(find.text('出库'), findsWidgets);
      expect(find.text('归还'), findsWidgets);
      expect(find.text('盘点'), findsWidgets);
      expect(find.text('设置'), findsWidgets);
    });

    testWidgets('no business logic triggered by default', (tester) async {
      bool businessTriggered = false;
      await tester.pumpWidget(
        wrapApp(
          WarehouseShellScannerEntry(
            adapter: MockScannerAdapter(),
            onCheckoutSubmit: (_) => businessTriggered = true,
          ),
        ),
      );
      expect(businessTriggered, isFalse);
    });

    testWidgets('scan result display preserved', (tester) async {
      String? captured;
      await tester.pumpWidget(
        wrapApp(
          WarehouseShellScannerEntry(
            adapter: MockScannerAdapter(),
            onScanResult: (code) => captured = code,
          ),
        ),
      );
      expect(captured, isNull);
    });

    // task-041: the Debug manual-code overlay was removed from the user-
    // visible UI entirely.  Real paper-label scanning is the only entry.
    testWidgets('debug manual input is NOT rendered', (tester) async {
      await tester.pumpWidget(
        wrapApp(WarehouseShellScannerEntry(adapter: MockScannerAdapter())),
      );
      expect(find.textContaining('Debug'), findsNothing);
      expect(find.text('手动输入扫码值'), findsNothing);
    });

    testWidgets('session-expired fetch result fires onSessionExpired', (
      tester,
    ) async {
      bool expired = false;
      await tester.pumpWidget(
        wrapApp(
          WarehouseShellScannerEntry(
            adapter: MockScannerAdapter(),
            apiClient: _ExpiredApiClient(),
            onSessionExpired: () => expired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(expired, isTrue);
    });
  });
}

class _ExpiredApiClient implements WarehouseApiClient {
  WarehouseApiResult<T> _failure<T>() {
    return const WarehouseApiResult(success: false, message: '未登录或会话已过期');
  }

  @override
  Future<WarehouseApiResult<WarehouseItem>> findItemByCode(String code) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<List<BorrowRecord>>> findBorrowersByQrcode(
    String qrcode,
  ) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<BorrowRecord>> getBorrowerDetail(
    int inventoryId,
    int borrowerUserId,
  ) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitCheckout(
    CheckoutSubmitPayload payload,
  ) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<List<CheckoutRecord>>>
  fetchCheckoutRecords() async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitReturn(
    ReturnSubmitPayload payload,
  ) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<List<ReturnRecord>>> fetchReturnRecords() async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<BusinessSubmitResult>> submitInventoryCheck(
    InventoryCheckSubmitPayload payload,
  ) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<List<InventoryCheckRecord>>>
  fetchInventoryCheckRecords() async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<AuthSession>> login(
    String username,
    String password,
  ) async {
    return _failure();
  }

  @override
  Future<WarehouseApiResult<void>> logout() async {
    return _failure();
  }
}
