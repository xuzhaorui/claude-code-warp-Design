// Pure business rules for the inventory check (盘点) form.
// Maps to `src/components/Forms/InventoryCheckForm.jsx` lines 6-22.
// Zero Flutter dependency — pure Dart, no BuildContext, no API, no storage.
// Non-goals: UI rendering, API calls, persistence, state management.

// ---- Difference type ----

/// 盘点差异类型
enum InventoryCheckDiffType {
  /// 盘盈 — actual > book
  surplus,
  /// 盘亏 — actual < book
  shortage,
  /// 无差异 — actual == book
  balanced,
}

// ---- Data classes ----

/// Snapshot of the inventory item being checked.
class InventoryCheckItemSnapshot {
  const InventoryCheckItemSnapshot({
    required this.id,
    required this.stockQty,
    this.itemName = '',
    this.code = '',
    this.spec = '',
  });

  /// Inventory item database id.
  final int id;

  /// Current system/book quantity.
  final int stockQty;

  /// Item name (货物名称).
  final String itemName;

  /// Item code / freight number (编号).
  final String code;

  /// Specification (规格).
  final String spec;
}

/// Raw user inputs to the inventory check form.
class InventoryCheckFormInput {
  const InventoryCheckFormInput({
    this.actualQty = '',
    this.remark = '',
  });

  /// Raw actual quantity string from stepper.
  final String actualQty;

  /// Remark for the inventory check.
  final String remark;
}

/// Result of evaluating [InventoryCheckFormInput] against the item.
class InventoryCheckFormEvaluation {
  const InventoryCheckFormEvaluation({
    required this.actualQty,
    required this.diffQty,
    required this.diffType,
    required this.canSubmit,
  });

  /// Parsed actual quantity (0 if empty / non-numeric / negative).
  final int actualQty;

  /// Difference between actual and book: actualQty - stockQty.
  final int diffQty;

  /// Type of difference: surplus / shortage / balanced.
  final InventoryCheckDiffType diffType;

  /// Whether submission is allowed.
  /// Always true in the Web (line 13: `const canSubmit = true;`).
  /// We follow the Web exactly — the only guard is on the caller side.
  final bool canSubmit;
}

/// Payload to be sent to the API on submit.
class InventoryCheckSubmitPayload {
  const InventoryCheckSubmitPayload({
    required this.inventoryId,
    required this.actualQty,
    this.remark = '',
  });

  final int inventoryId;
  final int actualQty;
  final String remark;
}

// ---- Rules ----

/// Pure evaluation and payload builder for the inventory check form.
///
/// Every method is stateless and deterministic: same input → same output.
class InventoryCheckFormRules {
  InventoryCheckFormRules._();

  /// Evaluates raw [input] against [item] and returns an
  /// [InventoryCheckFormEvaluation].
  ///
  /// Follows `src/components/Forms/InventoryCheckForm.jsx` lines 10-13 exactly:
  /// - `actualQty` = parse input, negatives clamped to 0
  /// - `diffQty` = actualQty - stockQty
  /// - `diffType` based on diffQty sign
  /// - `canSubmit` = true (Web line 13)
  ///
  /// **Why always canSubmit=true?**
  /// The Web InventoryCheckForm.jsx has `const canSubmit = true;` (line 13).
  /// There is no validation gate — the stepper clamps to [0, 99999] and the
  /// button is never disabled. We match this exact behavior.
  static InventoryCheckFormEvaluation evaluate({
    required InventoryCheckFormInput input,
    required InventoryCheckItemSnapshot item,
  }) {
    final qtyRaw = _parseInt(input.actualQty);
    final actualQty = qtyRaw < 0 ? 0 : qtyRaw;
    final diffQty = actualQty - item.stockQty;

    final diffType = diffQty > 0
        ? InventoryCheckDiffType.surplus
        : diffQty < 0
            ? InventoryCheckDiffType.shortage
            : InventoryCheckDiffType.balanced;

    return InventoryCheckFormEvaluation(
      actualQty: actualQty,
      diffQty: diffQty,
      diffType: diffType,
      canSubmit: true,
    );
  }

  /// Builds the [InventoryCheckSubmitPayload] from [input] and [item].
  ///
  /// Always returns a payload (never null) because `canSubmit` is always true
  /// per the Web behavior.  We still guard: if evaluation flags !canSubmit,
  /// return null — but under current rules this branch is unreachable.
  ///
  /// Maps to Web lines 15-21:
  /// - `inventoryId` = item.id
  /// - `actualQty` = parsed actual quantity
  /// - `remark` = input remark (may be empty)
  static InventoryCheckSubmitPayload? buildPayload({
    required InventoryCheckFormInput input,
    required InventoryCheckItemSnapshot item,
  }) {
    final evaluation = evaluate(input: input, item: item);
    if (!evaluation.canSubmit) return null;

    return InventoryCheckSubmitPayload(
      inventoryId: item.id,
      actualQty: evaluation.actualQty,
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
