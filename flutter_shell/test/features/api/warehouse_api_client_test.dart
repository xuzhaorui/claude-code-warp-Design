import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/api/warehouse_api_client.dart';
import 'package:wms_app/features/api/warehouse_api_models.dart';
import 'package:wms_app/features/api/mock_warehouse_api_client.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';

void main() {
  group('WarehouseApiClient contract', () {
    test('contract is abstract and can be implemented by MockClient', () {
      // The compiler enforces that MockWarehouseApiClient implements
      // all methods of WarehouseApiClient.  This test verifies the
      // contract is sound at runtime.
      final WarehouseApiClient client = MockWarehouseApiClient();
      expect(client, isA<WarehouseApiClient>());
    });
  });

  group('MockWarehouseApiClient - scan lookup', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('known code returns item', () async {
      final result = await client.findItemByCode('P293');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.itemName, 'Widget Pro');
      expect(result.data!.stockQty, 50);
      expect(result.data!.costPrice, 25.0);
    });

    test('unknown code returns failure', () async {
      final result = await client.findItemByCode('UNKNOWN-999');
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('未找到'));
    });

    test('second known code returns correct item', () async {
      final result = await client.findItemByCode('SKU-TEST-001');
      expect(result.isSuccess, isTrue);
      expect(result.data!.itemName, 'Test Sku');
      expect(result.data!.stockQty, 100);
    });

    test('DTO preserves all fields', () async {
      final result = await client.findItemByCode('P293');
      final item = result.data!;
      expect(item.id, 1001);
      expect(item.warehouse, '主仓库');
      expect(item.code, 'WP-001');
      expect(item.spec, '500ml');
    });
  });

  group('MockWarehouseApiClient - borrow lookup', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('known qrcode returns borrow records', () async {
      final result = await client.findBorrowersByQrcode('P293');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotEmpty);
      expect(result.data!.first.borrower, '张三');
    });

    test('unknown qrcode returns failure', () async {
      final result = await client.findBorrowersByQrcode('UNKNOWN');
      expect(result.isSuccess, isFalse);
    });

    test('borrower detail returns correct record', () async {
      final result = await client.getBorrowerDetail(1001, 201);
      expect(result.isSuccess, isTrue);
      expect(result.data!.borrower, '张三');
    });

    test('unknown borrower detail returns failure', () async {
      final result = await client.getBorrowerDetail(9999, 9999);
      expect(result.isSuccess, isFalse);
    });
  });

  group('MockWarehouseApiClient - checkout', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('submit returns success', () async {
      final payload = const CheckoutSubmitPayload(
        inventoryId: 1001,
        quantity: 5,
        type: 1,
      );
      final result = await client.submitCheckout(payload);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
    });

    test('fetch records returns empty list', () async {
      final result = await client.fetchCheckoutRecords();
      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });
  });

  group('MockWarehouseApiClient - return', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('submit returns success', () async {
      final payload = const ReturnSubmitPayload(
        loanId: 201,
        freightId: 202,
        storageId: 203,
        returnQty: 10,
      );
      final result = await client.submitReturn(payload);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
    });

    test('fetch records returns empty list', () async {
      final result = await client.fetchReturnRecords();
      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });
  });

  group('MockWarehouseApiClient - inventory check', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('submit returns success', () async {
      final payload = const InventoryCheckSubmitPayload(
        inventoryId: 3001,
        actualQty: 95,
      );
      final result = await client.submitInventoryCheck(payload);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
    });

    test('fetch records returns empty list', () async {
      final result = await client.fetchInventoryCheckRecords();
      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });
  });

  group('MockWarehouseApiClient - failure mode', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('fail mode makes checkout fail', () async {
      client.setFailMode(true);
      final result = await client.submitCheckout(
        const CheckoutSubmitPayload(inventoryId: 1, quantity: 1, type: 1),
      );
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('失败'));
    });

    test('fail mode makes return fail', () async {
      client.setFailMode(true);
      final result = await client.submitReturn(
        const ReturnSubmitPayload(loanId: 1, freightId: 1, storageId: 1, returnQty: 1),
      );
      expect(result.isSuccess, isFalse);
    });

    test('fail mode makes inventory check fail', () async {
      client.setFailMode(true);
      final result = await client.submitInventoryCheck(
        const InventoryCheckSubmitPayload(inventoryId: 1, actualQty: 1),
      );
      expect(result.isSuccess, isFalse);
    });
  });

  group('WarehouseApiModels', () {
    test('WarehouseItem json roundtrip', () {
      final item = WarehouseItem(
        id: 42,
        warehouse: '主仓库',
        itemName: '测试物品',
        code: 'TEST-001',
        spec: '500ml',
        stockQty: 100,
        costPrice: 25.5,
      );
      final json = item.toJson();
      final restored = WarehouseItem.fromJson(json);
      expect(restored.id, 42);
      expect(restored.itemName, '测试物品');
      expect(restored.stockQty, 100);
      expect(restored.costPrice, 25.5);
    });

    test('BorrowRecord json roundtrip', () {
      final record = BorrowRecord(
        id: 1,
        loanId: 10,
        inventoryId: 100,
        borrower: '张三',
        borrowQty: 30,
      );
      final json = record.toJson();
      final restored = BorrowRecord.fromJson(json);
      expect(restored.loanId, 10);
      expect(restored.borrower, '张三');
      expect(restored.borrowQty, 30);
    });

    test('WarehouseApiResult models success correctly', () {
      const result = WarehouseApiResult(success: true, message: 'ok');
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('WarehouseApiResult models failure correctly', () {
      const result = WarehouseApiResult(success: false, message: 'error');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });
  });

  group('MockWarehouseApiClient - auth', () {
    late MockWarehouseApiClient client;

    setUp(() {
      client = MockWarehouseApiClient();
    });

    test('login returns session', () async {
      final result = await client.login('admin', 'password123');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.username, 'admin');
    });

    test('login fail mode returns failure', () async {
      client.setFailMode(true);
      final result = await client.login('admin', 'wrong');
      expect(result.isSuccess, isFalse);
    });

    test('logout returns success', () async {
      final result = await client.logout();
      expect(result.isSuccess, isTrue);
    });
  });
}
