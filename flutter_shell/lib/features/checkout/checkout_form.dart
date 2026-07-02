import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/form_widgets.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../api/warehouse_api_client.dart';
import 'checkout_form_rules.dart';

/// Checkout (出库) form — Web-parity two-column layout.
///
/// Left panel: item info (库存 badge + 货物名称/仓库/编号/规格).
/// Right panel: 外销/外借 segmented, 出库数量 stepper, sale fields / remark,
/// 成本单价, black 提交 button.
///
/// All business logic (overStock, isLoss, canSubmit, payload, submit)
/// delegates to [CheckoutFormRules] and is unchanged.  Shared widgets come
/// from [form_widgets.dart].
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
  String _quantity = '1';
  CheckoutMethod _method = CheckoutMethod.sale;
  String _saleTotalPrice = '';
  String _remark = '';
  bool _confirmLoss = false;

  bool _isSubmitting = false;
  String? _submitError;

  // Persistent TextEditingControllers to avoid cursor-position issues.
  late final TextEditingController _qtyController;
  late final TextEditingController _saleTotalController;
  late final TextEditingController _remarkController;

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
    _qtyController = TextEditingController(text: '1');
    _saleTotalController = TextEditingController();
    _remarkController = TextEditingController();
    _qtyController.addListener(_onQtyListener);
    _saleTotalController.addListener(_onSaleTotalListener);
    _remarkController.addListener(_onRemarkListener);
    _evaluation = CheckoutFormRules.evaluate(input: _input, item: widget.item);
  }

  @override
  void dispose() {
    _qtyController.removeListener(_onQtyListener);
    _saleTotalController.removeListener(_onSaleTotalListener);
    _remarkController.removeListener(_onRemarkListener);
    _qtyController.dispose();
    _saleTotalController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _onQtyListener() {
    final raw = _qtyController.text;
    if (raw.isEmpty) {
      _quantity = '1';
    } else {
      final n = int.tryParse(raw);
      if (n != null) _quantity = n.clamp(1, widget.item.stockQty).toString();
    }
    _confirmLoss = false;
    _recompute();
  }

  void _onSaleTotalListener() {
    _saleTotalPrice = _saleTotalController.text;
    _confirmLoss = false;
    _recompute();
  }

  void _onRemarkListener() {
    _remark = _remarkController.text;
    _recompute();
  }

  void _recompute() {
    setState(() {
      _evaluation = CheckoutFormRules.evaluate(input: _input, item: widget.item);
    });
  }

  void _onQuantityChanged(num v) {
    _quantity = v.toString();
    _confirmLoss = false;
    _qtyController.text = _quantity;
    _qtyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _quantity.length),
    );
    _recompute();
  }

  void _onMethodChanged(CheckoutMethod m) {
    _method = m;
    _confirmLoss = false;
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

    try {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = '请求异常：$e';
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
          ItemInfoPanel(
            children: [
              StockBadge(label: '库存', value: '${item.stockQty}'),
              const SizedBox(height: AppSpacing.md),
              InfoField(label: '货物名称', value: item.itemName),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '仓库', value: item.warehouse),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '编号', value: item.code),
              const SizedBox(height: AppSpacing.sm),
              InfoField(label: '规格', value: item.spec),
            ],
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
                  BlackStepper(
                    label: '出库数量',
                    controller: _qtyController,
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
                      controller: _saleTotalController,
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
                    _RemarkField(label: '出库备注（选填）', controller: _remarkController),
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
                  BlackSubmitButton(
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

// ── Checkout-specific: black segmented control (Web method selector) ──

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
                  color: active ? AppDesignColors.primary : null,
                  borderRadius: BorderRadius.all(AppRadii.pill),
                ),
                child: Text(
                  o.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: active ? AppDesignColors.textPrimary : AppDesignColors.textSecondary,
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

// ── Checkout-specific: sale price field (Web Stepper controls=false) ──

class _SalePriceField extends StatelessWidget {
  const _SalePriceField({required this.controller});
  final TextEditingController controller;

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
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                LengthLimitingTextInputFormatter(10),
              ],
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                prefixText: '¥ ',
                hintText: '0',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared remark field (checkout/return/inventory) ──

class _RemarkField extends StatelessWidget {
  const _RemarkField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

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
          Text(label, style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
          TextFormField(
            controller: controller,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: AppSpacing.xs),
            ),
          ),
        ],
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
