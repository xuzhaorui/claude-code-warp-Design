import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/return_form/return_form_rules.dart';

void main() {
  // Shared fixture
  const record = ReturnBorrowRecordSnapshot(
    loanId: 101,
    freightId: 202,
    storageId: 303,
    borrowQty: 50,
    costPrice: 30.0,
    itemName: '测试货物',
    borrower: '张三',
    warehouse: '主仓库',
  );

  group('evaluate', () {
    // 1. returnQty > 0 且不超过 borrowQty，可以提交
    test('returnQty=5 ≤ borrowQty=50 → canSubmit=true', () {
      final input = ReturnFormInput(returnQty: '5');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.qty, 5);
      expect(r.overQty, isFalse);
      expect(r.canSubmit, isTrue);
    });

    // 2. returnQty 为空，不可提交
    test('returnQty="" → canSubmit=false', () {
      final input = ReturnFormInput(returnQty: '');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.qty, 0);
      expect(r.canSubmit, isFalse);
    });

    // 3. returnQty 为 0，不可提交
    test('returnQty="0" → canSubmit=false', () {
      final input = ReturnFormInput(returnQty: '0');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.qty, 0);
      expect(r.canSubmit, isFalse);
    });

    // 4. returnQty 超过 borrowQty，overQty=true 且不可提交
    test('returnQty=60 > borrowQty=50 → overQty=true, canSubmit=false', () {
      final input = ReturnFormInput(returnQty: '60');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.overQty, isTrue);
      expect(r.canSubmit, isFalse);
    });

    // 5. returnQty 等于 borrowQty，可以提交
    test('returnQty=50 = borrowQty=50 → canSubmit=true', () {
      final input = ReturnFormInput(returnQty: '50');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.qty, 50);
      expect(r.overQty, isFalse);
      expect(r.canSubmit, isTrue);
    });

    // 6. 非数字 returnQty 按 0 处理
    test('non-numeric returnQty → qty=0, canSubmit=false', () {
      final input = ReturnFormInput(returnQty: 'abc');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.qty, 0);
      expect(r.canSubmit, isFalse);
    });

    // 7. 负数 returnQty 按 0 处理
    test('negative returnQty → qty=0, canSubmit=false', () {
      final input = ReturnFormInput(returnQty: '-5');
      final r = ReturnFormRules.evaluate(input: input, record: record);
      expect(r.qty, 0);
      expect(r.canSubmit, isFalse);
    });
  });

  group('buildPayload', () {
    // 8. buildPayload 在 canSubmit=false 时返回 null
    test('canSubmit=false → buildPayload returns null', () {
      final input = ReturnFormInput(returnQty: '0');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNull);
    });

    // 9. payload 映射正确：loanId
    test('payload contains loanId', () {
      final input = ReturnFormInput(returnQty: '10');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNotNull);
      expect(p!.loanId, 101);
    });

    // 10. payload 映射正确：freightId
    test('payload contains freightId', () {
      final input = ReturnFormInput(returnQty: '10');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNotNull);
      expect(p!.freightId, 202);
    });

    // 11. payload 映射正确：storageId
    test('payload contains storageId', () {
      final input = ReturnFormInput(returnQty: '10');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNotNull);
      expect(p!.storageId, 303);
    });

    // 12. payload 映射正确：returnQty
    test('payload contains returnQty', () {
      final input = ReturnFormInput(returnQty: '25');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNotNull);
      expect(p!.returnQty, 25);
    });

    // 13. payload 映射正确：remark
    test('payload contains remark when provided', () {
      final input = ReturnFormInput(returnQty: '10', remark: '部分归还');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNotNull);
      expect(p!.remark, '部分归还');
    });

    // 14. remark 为空字符串时仍可提交
    test('remark="" → canSubmit=true (remark optional)', () {
      final input = ReturnFormInput(returnQty: '10', remark: '');
      final p = ReturnFormRules.buildPayload(input: input, record: record);
      expect(p, isNotNull);
      expect(p!.remark, '');
    });
  });

  // 15. borrowQty 为 0 时不可提交
  test('borrowQty=0 with any positive qty → cannot submit', () {
    const zeroRecord = ReturnBorrowRecordSnapshot(
      loanId: 1,
      freightId: 1,
      storageId: 1,
      borrowQty: 0,
    );
    final input = ReturnFormInput(returnQty: '5');
    final r = ReturnFormRules.evaluate(input: input, record: zeroRecord);
    // qty=5 > borrowQty=0 → overQty=true → canSubmit=false
    expect(r.overQty, isTrue);
    expect(r.canSubmit, isFalse);
  });
}
