import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';

void main() {
  // Shared fixture
  const item = InventoryCheckItemSnapshot(
    id: 42,
    stockQty: 100,
    itemName: '测试货物',
    code: 'ABC-001',
    spec: '500ml',
  );

  group('evaluate', () {
    // 1. actualQty 等于 stockQty → balanced / 无差异
    test('actualQty = stockQty → diffType=balanced', () {
      final input = InventoryCheckFormInput(actualQty: '100');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffType, InventoryCheckDiffType.balanced);
      expect(r.diffQty, 0);
      expect(r.canSubmit, isTrue);
    });

    // 2. actualQty 大于 stockQty → surplus / 盘盈
    test('actualQty > stockQty → diffType=surplus', () {
      final input = InventoryCheckFormInput(actualQty: '120');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffType, InventoryCheckDiffType.surplus);
      expect(r.diffQty, 20);
    });

    // 3. actualQty 小于 stockQty → shortage / 盘亏
    test('actualQty < stockQty → diffType=shortage', () {
      final input = InventoryCheckFormInput(actualQty: '80');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffType, InventoryCheckDiffType.shortage);
      expect(r.diffQty, -20);
    });

    // 4. diffQty 计算正确：正数
    test('diffQty positive: 150-100=50', () {
      final input = InventoryCheckFormInput(actualQty: '150');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffQty, 50);
    });

    // 5. diffQty 计算正确：负数
    test('diffQty negative: 30-100=-70', () {
      final input = InventoryCheckFormInput(actualQty: '30');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffQty, -70);
    });

    // 6. diffQty 计算正确：0
    test('diffQty zero: 100-100=0', () {
      final input = InventoryCheckFormInput(actualQty: '100');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffQty, 0);
    });

    // 7. actualQty 为空 → canSubmit=true (Web behavior: always true)
    test('actualQty="" → canSubmit=true, actualQty=0', () {
      final input = InventoryCheckFormInput(actualQty: '');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.actualQty, 0);
      expect(r.canSubmit, isTrue);
    });

    // 8. actualQty 为非数字 → 按 0 处理，canSubmit=true
    test('actualQty="abc" → actualQty=0, canSubmit=true', () {
      final input = InventoryCheckFormInput(actualQty: 'abc');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.actualQty, 0);
      expect(r.canSubmit, isTrue);
    });

    // 9. actualQty 为负数 → 按 0 处理
    test('actualQty="-5" → actualQty=0', () {
      final input = InventoryCheckFormInput(actualQty: '-5');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.actualQty, 0);
      expect(r.canSubmit, isTrue);
    });

    // 10. actualQty=0, stockQty>0 → shortage
    test('actualQty=0, stockQty=100 → shortage, diffQty=-100', () {
      final input = InventoryCheckFormInput(actualQty: '0');
      final r = InventoryCheckFormRules.evaluate(input: input, item: item);
      expect(r.diffType, InventoryCheckDiffType.shortage);
      expect(r.diffQty, -100);
    });

    // 11. stockQty=0, actualQty>0 → surplus
    test('stockQty=0, actualQty=50 → surplus', () {
      const zeroItem = InventoryCheckItemSnapshot(id: 1, stockQty: 0);
      final input = InventoryCheckFormInput(actualQty: '50');
      final r = InventoryCheckFormRules.evaluate(input: input, item: zeroItem);
      expect(r.diffType, InventoryCheckDiffType.surplus);
      expect(r.diffQty, 50);
    });
  });

  group('buildPayload', () {
    // 12. buildPayload never returns null (Web: canSubmit always true)
    test('buildPayload returns non-null for empty input', () {
      final input = InventoryCheckFormInput(actualQty: '');
      final p = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
    });

    // 13. payload 映射 inventoryId 正确
    test('payload contains inventoryId=42', () {
      final input = InventoryCheckFormInput(actualQty: '100');
      final p = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
      expect(p!.inventoryId, 42);
    });

    // 14. payload 映射 actualQty 正确
    test('payload contains actualQty', () {
      final input = InventoryCheckFormInput(actualQty: '75');
      final result = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(result, isNotNull);
      final p = result!;
      expect(p.actualQty, 75);
    });

    // 15. payload does NOT include stockQty/systemQty (Web only sends actualQty)
    test('payload does not send stockQty (matches Web)', () {
      final input = InventoryCheckFormInput(actualQty: '100');
      final result = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(result, isNotNull);
      final p = result!;
      // stockQty is not a field on InventoryCheckSubmitPayload
      expect(p.inventoryId, 42);
      expect(p.actualQty, 100);
    });

    // 16. payload 映射 diffQty — diffQty is NOT in payload (Web only uses
    //    diffQty for UI display, not in submit). Verify by omission.
    test('payload does not contain diffQty (UI-only field)', () {
      final input = InventoryCheckFormInput(actualQty: '100');
      final p = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
      // diffQty is an evaluation field, not a payload field — matches Web.
    });

    // 17. payload 映射 remark 正确
    test('payload contains remark', () {
      final input = InventoryCheckFormInput(actualQty: '100', remark: '盘点完成');
      final p = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
      expect(p!.remark, '盘点完成');
    });

    // 18. remark 为空字符串时仍可提交
    test('remark="" → payload is still valid', () {
      final input = InventoryCheckFormInput(actualQty: '100', remark: '');
      final p = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(p, isNotNull);
      expect(p!.remark, '');
    });

    // 19. long item display fields don't affect rules
    test('long item display fields do not affect evaluation', () {
      final longItem = InventoryCheckItemSnapshot(
        id: 99,
        stockQty: 50,
        itemName: '超长货物名称' * 20,
        code: '超长编号' * 20,
        spec: '超长规格' * 20,
      );
      final input = InventoryCheckFormInput(actualQty: '50');
      final r = InventoryCheckFormRules.evaluate(input: input, item: longItem);
      expect(r.diffType, InventoryCheckDiffType.balanced);
      expect(r.diffQty, 0);

      final p = InventoryCheckFormRules.buildPayload(input: input, item: longItem);
      expect(p, isNotNull);
      expect(p!.inventoryId, 99);
    });

    // 20. submit payload matches Web: inventoryId + actualQty + remark
    test('submit payload fields match Web InventoryCheckForm.jsx', () {
      final input = InventoryCheckFormInput(actualQty: '80', remark: '测试');
      final result = InventoryCheckFormRules.buildPayload(input: input, item: item);
      expect(result, isNotNull);
      final p = result!;
      // Web line 17-21: { inventoryId: item.id, actualQty, remark }
      expect(p.inventoryId, 42);
      expect(p.actualQty, 80);
      expect(p.remark, '测试');
    });
  });
}
