// Pure business rules for the checkout (出库) form.
// Maps to `src/components/Forms/CheckoutForm.jsx` lines 13-29.
// Zero Flutter dependency — pure Dart, no BuildContext, no API, no storage.
// Non-goals: UI rendering, API calls, persistence, state management.

// ---- Method ----

/// 出库方式
enum CheckoutMethod {
  /// 外销 (type=1)
  sale,
  /// 外借 (type=2)
  borrow,
}

// ---- Data classes ----

/// Immutable snapshot of the item being checked out.
class CheckoutItemSnapshot {
  const CheckoutItemSnapshot({
    required this.id,
    required this.stockQty,
    required this.costPrice,
  });

  /// Inventory item database id.
  final int id;

  /// Current stock quantity.
  final int stockQty;

  /// Unit cost price from the server (may be 0).
  final double costPrice;
}

/// Raw user inputs to the checkout form (may be empty / invalid).
class CheckoutFormInput {
  const CheckoutFormInput({
    this.quantity = '',
    this.method = CheckoutMethod.sale,
    this.saleTotalPrice = '',
    this.remark = '',
    this.confirmLoss = false,
    this.showCostPrice = true,
  });

  /// Raw quantity string from stepper (may be empty, non-numeric, or negative).
  final String quantity;

  /// Sale or borrow.
  final CheckoutMethod method;

  /// Raw sale total price string (may be empty or non-numeric).
  final String saleTotalPrice;

  /// Remark for borrow method.
  final String remark;

  /// Whether the user has confirmed a potential loss.
  final bool confirmLoss;

  /// Whether to show/check cost price for loss detection.
  final bool showCostPrice;
}

/// Result of evaluating [CheckoutFormInput] against the stock item.
class CheckoutFormEvaluation {
  const CheckoutFormEvaluation({
    required this.qty,
    required this.saleTotal,
    required this.saleUnitPrice,
    required this.overStock,
    required this.isLoss,
    required this.canSubmit,
  });

  /// Parsed quantity (0 if empty / non-numeric / negative).
  final int qty;

  /// Parsed sale total (0 if empty / non-numeric).
  final double saleTotal;

  /// Computed sale unit price (0 if qty <= 0).
  final double saleUnitPrice;

  /// True when qty exceeds item stock.
  final bool overStock;

  /// True when showCostPrice and sale unit price is below cost.
  final bool isLoss;

  /// True when all validation gates pass and submission is allowed.
  final bool canSubmit;
}

/// Payload to be sent to the API on submit.
class CheckoutSubmitPayload {
  const CheckoutSubmitPayload({
    required this.inventoryId,
    required this.quantity,
    required this.type,
    this.totalPrice,
    this.costUnitPrice,
    this.outDescription,
  });

  final int inventoryId;
  final int quantity;
  final int type; // 1 = 外销, 2 = 外借
  final double? totalPrice;
  final double? costUnitPrice;
  final String? outDescription;
}

// ---- Rules ----

/// Pure evaluation and payload builder for the checkout form.
///
/// Every method is stateless and deterministic: same input → same output.
class CheckoutFormRules {
  CheckoutFormRules._();

  /// Evaluates raw [input] against [item] and returns an [CheckoutFormEvaluation].
  ///
  /// Follows `src/components/Forms/CheckoutForm.jsx` lines 13-18 exactly:
  /// - `qty` = Number(quantity) || 0, but negatives are treated as 0
  ///   (the Web clamps but allows negatives through — this is a stricter
  ///   choice documented in the test report).
  /// - `saleTotal` = Number(saleTotalPrice) || 0
  /// - `overStock` = qty > stockQty
  /// - `isLoss` = showCostPrice && sale method && qty > 0 && saleTotal > 0
  ///              && saleUnitPrice < costPrice
  /// - `canSubmit` = qty > 0 && !overStock && (borrow || saleTotal > 0)
  ///                 && (!isLoss || confirmLoss)
  static CheckoutFormEvaluation evaluate({
    required CheckoutFormInput input,
    required CheckoutItemSnapshot item,
  }) {
    final qtyRaw = _parseInt(input.quantity);
    // _parseInt returns 0 for non-numeric; we additionally clamp negatives to 0.
    final qty = qtyRaw < 0 ? 0 : qtyRaw;

    final saleTotal = _parseDouble(input.saleTotalPrice);
    final saleUnitPrice = qty > 0 ? saleTotal / qty : 0.0;

    final overStock = qty > item.stockQty;
    final isLoss = input.showCostPrice &&
        input.method == CheckoutMethod.sale &&
        qty > 0 &&
        saleTotal > 0 &&
        saleUnitPrice < item.costPrice;

    final canSubmit = qty > 0 &&
        !overStock &&
        (input.method == CheckoutMethod.borrow || saleTotal > 0) &&
        (!isLoss || input.confirmLoss);

    return CheckoutFormEvaluation(
      qty: qty,
      saleTotal: saleTotal,
      saleUnitPrice: saleUnitPrice,
      overStock: overStock,
      isLoss: isLoss,
      canSubmit: canSubmit,
    );
  }

  /// Builds the [CheckoutSubmitPayload] from [input] and [item].
  ///
  /// Returns `null` when `canSubmit` is false, mirroring the Web's
  /// `if (!canSubmit) return;` (line 21).
  ///
  /// ## Why return null instead of throwing?
  /// The Web silently aborts on !canSubmit.  Throwing would force callers
  /// to wrap every submit in try/catch.  Returning null shifts the
  /// responsibility to the caller to check `canSubmit` first, matching the
  /// Web's guard-clause pattern.
  static CheckoutSubmitPayload? buildPayload({
    required CheckoutFormInput input,
    required CheckoutItemSnapshot item,
  }) {
    final evaluation = evaluate(input: input, item: item);
    if (!evaluation.canSubmit) return null;

    final isSale = input.method == CheckoutMethod.sale;

    return CheckoutSubmitPayload(
      inventoryId: item.id,
      quantity: evaluation.qty,
      type: isSale ? 1 : 2,
      totalPrice: isSale ? evaluation.saleTotal : null,
      costUnitPrice: isSale ? item.costPrice : null,
      outDescription: isSale ? null : (input.remark.isNotEmpty ? input.remark : null),
    );
  }

  // ---- Helpers ----

  /// Parses [s] as an integer.  Returns 0 on any parse failure.
  static int _parseInt(String s) {
    if (s.isEmpty) return 0;
    final n = int.tryParse(s);
    return n ?? 0;
  }

  /// Parses [s] as a double.  Returns 0.0 on any parse failure.
  static double _parseDouble(String s) {
    if (s.isEmpty) return 0.0;
    final n = double.tryParse(s);
    return n ?? 0.0;
  }
}
