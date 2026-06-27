import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/checkout/checkout_form_rules.dart';

void main() {
  // Shared fixture
  const item = CheckoutItemSnapshot(
    id: 42,
    stockQty: 100,
    costPrice: 50.0,
  );

  group('evaluate', () {
    // 1. 外销：数量 > 0 且销售总价 > 0，可以提交
    test('外销 qty>0 and saleTotal>0 → canSubmit=true', () {
      final input = CheckoutFormInput(
        quantity: '5',
        method: CheckoutMethod.sale,
        saleTotalPrice: '300',
        confirmLoss: false,
        showCostPrice: true,
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.qty, 5);
      expect(r.canSubmit, isTrue);
      expect(r.overStock, isFalse);
    });

    // 2. 外销：销售总价为空，不可提交
    test('外销 saleTotalPrice="" → canSubmit=false', () {
      final input = CheckoutFormInput(
        quantity: '5',
        method: CheckoutMethod.sale,
        saleTotalPrice: '',
        confirmLoss: false,
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.canSubmit, isFalse);
    });

    // 3. 外借：数量 > 0，即使销售总价为空，也可以提交
    test('外借 qty>0 saleTotal="" → canSubmit=true', () {
      final input = CheckoutFormInput(
        quantity: '5',
        method: CheckoutMethod.borrow,
        saleTotalPrice: '',
        confirmLoss: false,
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.canSubmit, isTrue);
    });

    // 4. 数量为 0，不可提交
    test('qty=0 → canSubmit=false', () {
      final input = CheckoutFormInput(
        quantity: '0',
        method: CheckoutMethod.sale,
        saleTotalPrice: '100',
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.canSubmit, isFalse);
    });

    // 5. 数量超过库存，overStock=true 且不可提交
    test('qty > stockQty → overStock=true, canSubmit=false', () {
      final input = CheckoutFormInput(
        quantity: '200',
        method: CheckoutMethod.sale,
        saleTotalPrice: '500',
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.overStock, isTrue);
      expect(r.canSubmit, isFalse);
    });

    // 6. 外销销售单价低于成本价，isLoss=true 且未确认不可提交
    test('外销 saleUnitPrice < costPrice → isLoss=true, canSubmit=false', () {
      final input = CheckoutFormInput(
        quantity: '10',
        method: CheckoutMethod.sale,
        saleTotalPrice: '300', // unit price = 30 < 50
        confirmLoss: false,
        showCostPrice: true,
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.isLoss, isTrue);
      expect(r.canSubmit, isFalse);
    });

    // 7. 亏损已确认，可以提交
    test('外销 isLoss=true but confirmLoss=true → canSubmit=true', () {
      final input = CheckoutFormInput(
        quantity: '10',
        method: CheckoutMethod.sale,
        saleTotalPrice: '300', // unit price = 30 < 50
        confirmLoss: true,
        showCostPrice: true,
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.isLoss, isTrue);
      expect(r.canSubmit, isTrue);
    });

    // 8. showCostPrice=false 时不触发亏损判断
    test('showCostPrice=false → isLoss=false even if unit price low', () {
      final input = CheckoutFormInput(
        quantity: '10',
        method: CheckoutMethod.sale,
        saleTotalPrice: '300', // unit price = 30 < 50
        confirmLoss: false,
        showCostPrice: false,
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.isLoss, isFalse);
      expect(r.canSubmit, isTrue);
    });

    // 9. saleUnitPrice 计算正确
    test('saleUnitPrice = saleTotal / qty', () {
      final input = CheckoutFormInput(
        quantity: '4',
        method: CheckoutMethod.sale,
        saleTotalPrice: '200',
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.saleUnitPrice, closeTo(50.0, 0.001));
    });

    // 10. 非数字 quantity 按 0 处理
    test('non-numeric quantity → qty=0', () {
      final input = CheckoutFormInput(
        quantity: 'abc',
        method: CheckoutMethod.sale,
        saleTotalPrice: '100',
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.qty, 0);
      expect(r.canSubmit, isFalse);
    });

    // 11. 非数字 saleTotalPrice 按 0 处理
    test('non-numeric saleTotalPrice → saleTotal=0', () {
      final input = CheckoutFormInput(
        quantity: '5',
        method: CheckoutMethod.sale,
        saleTotalPrice: 'xyz',
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.saleTotal, closeTo(0.0, 0.001));
      expect(r.canSubmit, isFalse);
    });

    // 12. 负数 quantity 不可提交
    test('negative quantity → qty=0, canSubmit=false', () {
      final input = CheckoutFormInput(
        quantity: '-5',
        method: CheckoutMethod.sale,
        saleTotalPrice: '100',
      );
      final r = CheckoutFormRules.evaluate(input: input, item: item);
      expect(r.qty, 0);
      expect(r.canSubmit, isFalse);
    });
  });

  group('buildPayload', () {
    // 13. 外销 payload 映射正确
    test('外销 → type=1, totalPrice, costUnitPrice', () {
      final input = CheckoutFormInput(
        quantity: '5',
        method: CheckoutMethod.sale,
        saleTotalPrice: '300',
      );
      final p = CheckoutFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
      expect(p!.inventoryId, 42);
      expect(p.quantity, 5);
      expect(p.type, 1);
      expect(p.totalPrice, closeTo(300.0, 0.001));
      expect(p.costUnitPrice, closeTo(50.0, 0.001));
      expect(p.outDescription, isNull);
    });

    // 14. 外借 payload 映射正确
    test('外借 → type=2, outDescription', () {
      final input = CheckoutFormInput(
        quantity: '3',
        method: CheckoutMethod.borrow,
        saleTotalPrice: '',
        remark: '测试借用',
      );
      final p = CheckoutFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
      expect(p!.inventoryId, 42);
      expect(p.quantity, 3);
      expect(p.type, 2);
      expect(p.totalPrice, isNull);
      expect(p.costUnitPrice, isNull);
      expect(p.outDescription, '测试借用');
    });

    // 15. buildPayload 在 canSubmit=false 时返回 null
    test('canSubmit=false → buildPayload returns null', () {
      final input = CheckoutFormInput(
        quantity: '0',
        method: CheckoutMethod.sale,
        saleTotalPrice: '',
      );
      final p = CheckoutFormRules.buildPayload(input: input, item: item);
      expect(p, isNull);
    });
  });
}
