import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_client.dart';
import 'checkout_form_rules.dart';

// ---- Component-local constants ----
//
// Per Design.md, component-local numeric constants (panel width, badge
// rotation/skew, stepper button sizes) are allowed when mirroring the Web
// layout and not promoting a new design token.
class _CF {
  _CF._();
  static const leftPanelWidth = 135.0;
  static const badgeRotate = -0.017; // ~ -1deg, Web rotate(-1deg)
  static const badgeSkew = -0.087; // ~ -5deg, Web skewX(-5deg)
  static const badgeInnerSkew = 0.14; // ~ +8deg, Web skewX(8deg) on text
  static const stepperHeight = 56.0;
  static const stepperBtnSize = 44.0;
  static const submitHeight = 52.0;
}

/// Checkout (出库) form — Web-parity two-column layout.
///
/// Left panel: item info (库存 badge + 货物名称/仓库/编号/规格).
/// Right panel: 外销/外借 segmented, 出库数量 stepper, sale fields / remark,
/// 成本单价, black 提交 button.
///
/// All business logic (overStock, isLoss, canSubmit, payload, submit)
/// delegates to [CheckoutFormRules] and is unchanged from the single-column
/// version.  Only the visual tree was rewritten to match the Web form.
class CheckoutFormMin extends StatefulWidget {
  const CheckoutFormMin({
    super.key,
    required this.item,
    this.operatorName,
    this.showCostPrice = true,
    this.apiClient,
    this.onSubmit,
    this.onClose,
    this.onSubmitSuccess,
  });

  final CheckoutItemSnapshot item;
  final String? operatorName;
  final bool showCostPrice;
  final WarehouseApiClient? apiClient;
  final ValueChanged<CheckoutSubmitPayload>? onSubmit;
  final VoidCallback? onClose;
  final VoidCallback? onSubmitSuccess;

  @override
  State<CheckoutFormMin> createState() => _CheckoutFormMinState();
}

class _CheckoutFormMinState extends State<CheckoutFormMin> {
  String _quantity = '';
  CheckoutMethod _method = CheckoutMethod.sale;
  String _saleTotalPrice = '';
  String _remark = '';
  bool _confirmLoss = false;

  bool _isSubmitting = false;
  String? _submitError;

  CheckoutFormInput get _input => CheckoutFormInput(
        quantity: _quantity,
        method: _method,
        saleTotalPrice: _saleTotalPrice,
        remark: _remark,
        confirmLoss: _confirmLoss,
        showCostPrice: widget.showCostPrice,
      );

  late CheckoutFormEvaluation _evaluation;

  @override
  void initState() {
    super.initState();
    _evaluation = CheckoutFormRules.evaluate(input: _input, item: widget.item);
  }

  void _recompute() {
    setState(() {
      _evaluation = CheckoutFormRules.evaluate(input: _input, item: widget.item);
    });
  }

  void _onQuantityChanged(num v) {
    _quantity = v.toString();
    _confirmLoss = false;
    _recompute();
  }

  void _onMethodChanged(CheckoutMethod m) {
    _method = m;
    _confirmLoss = false;
    _recompute();
  }

  void _onSaleTotalChanged(String v) {
    _saleTotalPrice = v;
    _confirmLoss = false;
    _recompute();
  }

  void _onRemarkChanged(String v) {
    _remark = v;
    _recompute();
  }

  Future<void> _handleSubmit() async {
    final payload = CheckoutFormRules.buildPayload(input: _input, item: widget.item);
    if (payload == null) return;

    final api = widget.apiClient;
    if (api == null) {
      widget.onSubmit?.call(payload);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final result = await api.submitCheckout(payload);

    if (!mounted) return;

    if (result.isSuccess) {
      widget.onSubmitSuccess?.call();
      widget.onClose?.call();
    } else {
      setState(() {
        _isSubmitting = false;
        _submitError = result.message ?? '出库提交失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ev = _evaluation;
    final isSale = _method == CheckoutMethod.sale;
    final canSubmit = ev.canSubmit && !_isSubmitting;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: item info panel ──
          Container(
            width: _CF.leftPanelWidth,
            decoration: const BoxDecoration(
              color: AppDesignColors.surface,
              border: Border(
                right: BorderSide(color: AppDesignColors.borderMuted),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StockBadge(stockQty: item.stockQty),
                  const SizedBox(height: AppSpacing.md),
                  _InfoField(label: '货物名称', value: item.itemName),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoField(label: '仓库', value: item.warehouse),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoField(label: '编号', value: item.code),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoField(label: '规格', value: item.spec),
                ],
              ),
            ),
          ),
          // ── Right: form panel ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BlackSegmented<CheckoutMethod>(
                    options: const [
                      _SegOption(value: CheckoutMethod.sale, label: '外销'),
                      _SegOption(value: CheckoutMethod.borrow, label: '外借'),
                    ],
                    selectedValue: _method,
                    onChanged: _onMethodChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BlackStepper(
                    label: '出库数量',
                    value: _quantity,
                    min: 1,
                    max: item.stockQty,
                    error: ev.overStock,
                    onChanged: _onQuantityChanged,
                  ),
                  if (ev.overStock)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
                      child: Text(
                        '超出库存数量（库存: ${item.stockQty}）',
                        style: AppTextStyles.caption.copyWith(
                          color: AppDesignColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (isSale) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SalePriceField(
                      value: _saleTotalPrice,
                      onChanged: _onSaleTotalChanged,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppDesignColors.surfaceMuted,
                        borderRadius: BorderRadius.all(AppRadii.md),
                      ),
                      child: Row(
                        children: [
                          Text('销售单价：',
                              style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
                          const Spacer(),
                          Text('¥${ev.saleUnitPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (ev.isLoss && !_confirmLoss) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _LossWarning(costPrice: item.costPrice, onConfirm: () => setState(() => _confirmLoss = true)),
                    ],
                    if (ev.isLoss && _confirmLoss)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text('已确认亏损操作',
                            style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
                      ),
                  ],
                  if (!isSale) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RemarkField(value: _remark, onChanged: _onRemarkChanged),
                  ],
                  if (widget.showCostPrice) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('成本单价：¥${item.costPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
                  ],
                  if (_submitError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(_submitError!,
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _BlackSubmitButton(
                    text: _isSubmitting ? '提交中...' : '提交',
                    loading: _isSubmitting,
                    onPressed: canSubmit ? _handleSubmit : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left-panel: rotated 库存 badge (Web BadgeField) ──

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stockQty});
  final int stockQty;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _CF.badgeRotate,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppDesignColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewX(_CF.badgeSkew),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppDesignColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(_CF.badgeInnerSkew),
              child: Text(
                '$stockQty',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppDesignColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Left-panel: label/value info field (Web InfoField) ──

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
              color: AppDesignColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Right-panel: black segmented control (Web method selector) ──

class _BlackSegmented<T> extends StatelessWidget {
  const _BlackSegmented({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });
  final List<_SegOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.pill),
      ),
      child: Row(
        children: options.map((o) {
          final active = o.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: active ? AppDesignColors.textPrimary : null,
                  borderRadius: BorderRadius.all(AppRadii.pill),
                ),
                child: Text(
                  o.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: active ? AppDesignColors.scannerLight : AppDesignColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SegOption<T> {
  const _SegOption({required this.value, required this.label});
  final T value;
  final String label;
}

// ── Right-panel: black-accent stepper (Web Stepper) ──

class _BlackStepper extends StatelessWidget {
  const _BlackStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.error,
    required this.onChanged,
  });
  final String label;
  final String value;
  final int min;
  final int max;
  final bool error;
  final ValueChanged<num> onChanged;

  int get _current {
    if (value.isEmpty) return min;
    return int.tryParse(value) ?? min;
  }

  void _step(int dir) {
    final next = (_current + dir).clamp(min, max);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _CF.stepperHeight,
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
        border: error
            ? Border.all(color: Theme.of(context).colorScheme.error, width: 2)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating label
          Positioned(
            top: 0,
            left: AppSpacing.md,
            child: Container(
              color: AppDesignColors.surfaceMuted,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppDesignColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _roundButton(
                glyph: '−',
                onTap: () => _step(-1),
                dark: false,
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: value.isEmpty ? '' : value),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                  onChanged: (raw) {
                    if (raw.isEmpty) {
                      onChanged(min);
                      return;
                    }
                    final n = int.tryParse(raw);
                    if (n != null) onChanged(n.clamp(min, max));
                  },
                ),
              ),
              _roundButton(
                glyph: '+',
                onTap: () => _step(1),
                dark: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required String glyph, required VoidCallback onTap, required bool dark}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _CF.stepperBtnSize,
        height: _CF.stepperBtnSize,
        decoration: BoxDecoration(
          color: dark ? AppDesignColors.textPrimary : AppDesignColors.borderMuted,
          borderRadius: BorderRadius.all(AppRadii.sm),
        ),
        child: Center(
          child: Text(
            glyph,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w700,
              color: dark ? AppDesignColors.scannerLight : AppDesignColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Right-panel: sale price field (Web Stepper controls=false) ──

class _SalePriceField extends StatelessWidget {
  const _SalePriceField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text('销售总价', style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: TextEditingController(text: value),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                prefixText: '¥ ',
                hintText: '0',
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Right-panel: remark field (外借) ──

class _RemarkField extends StatelessWidget {
  const _RemarkField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('出库备注（选填）', style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
          TextFormField(
            controller: TextEditingController(text: value),
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: AppSpacing.xs),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Right-panel: black submit button (Web 提交) ──

class _BlackSubmitButton extends StatelessWidget {
  const _BlackSubmitButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: SizedBox(
        width: double.infinity,
        height: _CF.submitHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignColors.textPrimary,
            foregroundColor: AppDesignColors.scannerLight,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppDesignColors.scannerLight),
                  ),
                )
              : Text(text, style: AppTextStyles.label),
        ),
      ),
    );
  }
}

class _LossWarning extends StatelessWidget {
  const _LossWarning({required this.costPrice, required this.onConfirm});
  final double costPrice;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('销售单价低于成本单价（¥${costPrice.toStringAsFixed(2)}），存在亏损风险',
              style: AppTextStyles.caption.copyWith(color: cs.error)),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onConfirm,
            child: Text('确认继续',
                style: AppTextStyles.caption.copyWith(
                    color: cs.error, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
