// Pure business rules for the return (归还) form.
// Maps to `src/components/Forms/ReturnForm.jsx` lines 10-22.
// Zero Flutter dependency — pure Dart, no BuildContext, no API, no storage.
// Non-goals: UI rendering, API calls, persistence, state management.

// ---- Data classes ----

/// Snapshot of a borrow record being returned.
class ReturnBorrowRecordSnapshot {
  const ReturnBorrowRecordSnapshot({
    required this.loanId,
    required this.freightId,
    required this.storageId,
    required this.borrowQty,
    this.costPrice = 0.0,
    this.itemName = '',
    this.borrower = '',
    this.warehouse = '',
  });

  /// Borrow record database id.
  final int loanId;

  /// Freight/item id.
  final int freightId;

  /// Storage/warehouse id.
  final int storageId;

  /// Currently borrowed quantity.
  final int borrowQty;

  /// Unit cost price (may be 0).
  final double costPrice;

  /// Item name (货物名称).
  final String itemName;

  /// Borrower name (外借人).
  final String borrower;

  /// Warehouse name (仓库).
  final String warehouse;
}

/// Raw user inputs to the return form (may be empty / invalid).
class ReturnFormInput {
  const ReturnFormInput({
    this.returnQty = '',
    this.remark = '',
  });

  /// Raw return quantity string (may be empty, non-numeric, or negative).
  final String returnQty;

  /// Remark for the return.
  final String remark;
}

/// Result of evaluating [ReturnFormInput] against the borrow record.
class ReturnFormEvaluation {
  const ReturnFormEvaluation({
    required this.qty,
    required this.overQty,
    required this.canSubmit,
  });

  /// Parsed quantity (0 if empty / non-numeric / negative).
  final int qty;

  /// True when qty exceeds the borrowed quantity.
  final bool overQty;

  /// True when all validation gates pass and submission is allowed.
  final bool canSubmit;
}

/// Payload to be sent to the API on submit.
class ReturnSubmitPayload {
  const ReturnSubmitPayload({
    required this.loanId,
    required this.freightId,
    required this.storageId,
    required this.returnQty,
    this.remark = '',
  });

  final int loanId;
  final int freightId;
  final int storageId;
  final int returnQty;
  final String remark;
}

// ---- Rules ----

/// Pure evaluation and payload builder for the return form.
///
/// Every method is stateless and deterministic: same input → same output.
class ReturnFormRules {
  ReturnFormRules._();

  /// Evaluates raw [input] against [record] and returns a [ReturnFormEvaluation].
  ///
  /// Follows `src/components/Forms/ReturnForm.jsx` lines 10-12 exactly:
  /// - `qty` = Number(returnQty) || 0, with negatives clamped to 0
  ///   (consistent with CheckoutFormRules).
  /// - `overQty` = qty > borrowQty
  /// - `canSubmit` = qty > 0 && !overQty
  static ReturnFormEvaluation evaluate({
    required ReturnFormInput input,
    required ReturnBorrowRecordSnapshot record,
  }) {
    final qtyRaw = _parseInt(input.returnQty);
    final qty = qtyRaw < 0 ? 0 : qtyRaw;

    final overQty = qty > record.borrowQty;
    final canSubmit = qty > 0 && !overQty;

    return ReturnFormEvaluation(
      qty: qty,
      overQty: overQty,
      canSubmit: canSubmit,
    );
  }

  /// Builds the [ReturnSubmitPayload] from [input] and [record].
  ///
  /// Returns `null` when `canSubmit` is false, mirroring the Web's
  /// `if (!canSubmit) return;` (line 14).
  static ReturnSubmitPayload? buildPayload({
    required ReturnFormInput input,
    required ReturnBorrowRecordSnapshot record,
  }) {
    final evaluation = evaluate(input: input, record: record);
    if (!evaluation.canSubmit) return null;

    return ReturnSubmitPayload(
      loanId: record.loanId,
      freightId: record.freightId,
      storageId: record.storageId,
      returnQty: evaluation.qty,
      remark: input.remark,
    );
  }

  // ---- Helpers ----

  /// Parses [s] as an integer.  Returns 0 on any parse failure.
  static int _parseInt(String s) {
    if (s.isEmpty) return 0;
    final n = int.tryParse(s);
    return n ?? 0;
  }
}
