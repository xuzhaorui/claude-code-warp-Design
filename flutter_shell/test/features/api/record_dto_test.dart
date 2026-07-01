import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/api/warehouse_api_models.dart';

/// Web-parity tests for the record DTO `fromJson` mappers.
///
/// These lock down the exact backend field-name → normalized field mapping
/// (mirroring `src/api/outbound.js` mapCheckoutRecord, `return.js`
/// mapReturnRecord, `inventory.js mapInventoryCheckRecord`), so the Flutter
/// record list and detail sheet show the same fields as the Web app.
void main() {
  group('CheckoutRecord.fromJson', () {
    test('maps full backend shape to Web-parity fields', () {
      final r = CheckoutRecord.fromJson({
        'id': 1478,
        'inventoryId': 1001,
        'storageName': '主仓库',
        'freightName': 'Widget Pro',
        'freightNumber': 'WP-001',
        'specification': '500ml',
        'num': 5,
        'type': 1,
        'totalPrice': 250,
        'costUnitPrice': 25,
        'outDescription': '备注x',
        'operationNickName': '张三',
        'operationTime': '2026-07-01 10:00',
        'outState': 1,
      });
      expect(r.id, 1478);
      expect(r.itemName, 'Widget Pro');
      expect(r.warehouse, '主仓库');
      expect(r.code, 'WP-001');
      expect(r.spec, '500ml');
      expect(r.quantity, 5);
      expect(r.type, 1);
      expect(r.method, '外销');
      expect(r.saleTotalPrice, 250);
      expect(r.costPrice, 25);
      expect(r.remark, '备注x');
      expect(r.operatorName, '张三');
      expect(r.time, '2026-07-01 10:00');
      expect(r.status, '正常');
    });

    test('outState 2 maps to 已撤销', () {
      final r = CheckoutRecord.fromJson({'outState': 2});
      expect(r.status, '已撤销');
    });

    test('type 2 derives method 外借', () {
      final r = CheckoutRecord.fromJson({'type': 2});
      expect(r.method, '外借');
    });

    test('missing fields degrade to safe defaults, not null', () {
      final r = CheckoutRecord.fromJson({});
      expect(r.itemName, '');
      expect(r.quantity, 0);
      expect(r.status, '正常');
    });

    test('falls back to numberAndSpec split when freightNumber/spec absent', () {
      final r = CheckoutRecord.fromJson({'numberAndSpec': 'CODE123/1L'});
      expect(r.code, 'CODE123');
      expect(r.spec, '1L');
    });
  });

  group('ReturnRecord.fromJson', () {
    test('maps full backend shape', () {
      final r = ReturnRecord.fromJson({
        'id': 55,
        'freightName': 'Widget Pro',
        'warehouseName': '主仓库',
        'freightNumber': 'WP-001',
        'specification': '500ml',
        'num': 3,
        'inBorrowerUserName': '李四',
        'operationNickName': '张三',
        'operationTime': '2026-07-01 11:00',
        'inDescription': '归还备注',
        'inState': 1,
      });
      expect(r.itemName, 'Widget Pro');
      expect(r.warehouse, '主仓库');
      expect(r.returnQty, 3);
      expect(r.borrower, '李四');
      expect(r.operatorName, '张三');
      expect(r.remark, '归还备注');
      expect(r.status, '正常');
    });

    test('inState 2 maps to 已撤销', () {
      final r = ReturnRecord.fromJson({'inState': 2});
      expect(r.status, '已撤销');
    });
  });

  group('InventoryCheckRecord.fromJson', () {
    test('maps full backend shape', () {
      final r = InventoryCheckRecord.fromJson({
        'id': 9,
        'inventoryId': 1001,
        'freightName': 'Widget Pro',
        'storageName': '主仓库',
        'freightNumber': 'WP-001',
        'specification': '500ml',
        'warehousNum': 50,
        'physicalInventoryQuantity': 48,
        'difference': -2,
        'unitPrice': 25,
        'remark': '盘亏',
        'purchaseUserName': '王五',
        'purchaseTime': '2026-07-01 12:00',
      });
      expect(r.itemName, 'Widget Pro');
      expect(r.bookQty, 50);
      expect(r.actualQty, 48);
      expect(r.difference, -2);
      expect(r.costPrice, 25);
      expect(r.operatorName, '王五');
      // inventory status is always 正常 per Web mapper
      expect(r.status, '正常');
    });

    test('status always 正常 regardless of input', () {
      final r = InventoryCheckRecord.fromJson({});
      expect(r.status, '正常');
    });
  });
}
