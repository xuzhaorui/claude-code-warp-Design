import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_text_styles.dart';

// ---- AppTextField-specific constants ----

/// Layout constants derived from Design.md `input-default` and `helper-text`
/// component tokens.  These are component-local because they represent
/// sub-component sizing choices, not general design tokens.
class _ATC {
  _ATC._();
  static const helperVPad = 4.0;
}

// ---- Public widget ----

/// A themed input field that wraps `TextFormField` with Design.md
/// `input-default` token styling.
///
/// Maps to `src/components/Forms/BumbleInput.jsx`.  All colours, typography,
/// spacing and radii come from Design.md tokens / `AppTheme.light`.
/// Component-local sizing constants are in [_ATC].
///
/// Supported states:
/// - **Focus**: primary colour border (via theme `focusedBorder`)
/// - **Error**: `errorText` message shown below + error-coloured border
/// - **Disabled**: greyed out via Material default disabled handling
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.focusNode,
  });

  /// Floating label displayed inside the input field.
  final String? label;

  /// Placeholder hint when the field is empty.
  final String? hint;

  /// Optional external controller.
  final TextEditingController? controller;

  /// When non-null, shows an error message below the field and switches the
  /// border to the error colour.
  final String? errorText;

  /// Whether the field accepts input (default true).
  final bool enabled;

  /// Keyboard type (text, number, url, etc.).
  final TextInputType? keyboardType;

  /// Called every time the text value changes.
  final ValueChanged<String>? onChanged;

  /// Optional external focus node for focus-state coordination.
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != null && widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode!;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          // Design.md input-default height: 58px — implicit via contentPadding
          // + body line-height (16*1.5=24) + 2*16 = 56 ≈ 58.
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onTapOutside: (_) => _focusNode.unfocus(),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              errorText: hasError ? widget.errorText : null,
              errorStyle: AppTextStyles.caption.copyWith(
                color: cs.error,
              ),
              // Error border: same primary colour for consistency.
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(AppRadii.md),
                borderSide: BorderSide(color: cs.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(AppRadii.md),
                borderSide: BorderSide(color: AppDesignColors.primary),
              ),
            ),
          ),
        ),
        // Extra space when there's no error so layout doesn't shift.
        if (!hasError)
          Padding(
            padding: const EdgeInsets.only(top: _ATC.helperVPad),
            child: SizedBox(
              height: AppTextStyles.caption.fontSize! * (AppTextStyles.caption.height ?? 1.0),
              child: const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
