import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

/// Status badge color mapping based on Design.md palette.
///
/// Neutral statuses use surface-muted background with secondary text.
/// Warning/alert statuses use primary (terracotta) background with primary text.
/// Error/cancelled statuses use theme error color with light text.
class _StatusColors {
  const _StatusColors({required this.background, required this.text});

  final Color background;
  final Color text;

  static const _neutral = _StatusColors(
    background: AppDesignColors.surfaceMuted,
    text: AppDesignColors.textSecondary,
  );

  static const _alert = _StatusColors(
    background: AppDesignColors.primary,
    text: AppDesignColors.textPrimary,
  );

  /// Resolve error background from the current theme at build time.
  static _StatusColors _errorForTheme(ColorScheme colorScheme) {
    return _StatusColors(
      background: colorScheme.error,
      text: AppDesignColors.scannerLight,
    );
  }

  static _StatusColors forStatus(String status, ColorScheme colorScheme) {
    switch (status) {
      case '异常':
      case '亏损':
        return _alert;
      case '已撤销':
        return _errorForTheme(colorScheme);
      default:
        return _neutral;
    }
  }
}

/// A reusable card that displays a record's title, detail line, and optional
/// status badge, with a chevron tap target on the right.
///
/// Maps to `src/components/Records/RecordCard.jsx`. Uses only Design.md tokens
/// for colors, typography, spacing, and radii — no inline hardcoded visual
/// constants.
///
/// [index] controls staggered entrance delay (index * 50ms).
class RecordCard extends StatefulWidget {
  /// Primary record title (truncated if long).
  final String title;

  /// Secondary detail line (truncated if long).
  final String detail;

  /// Optional status label rendered as a pill badge.
  ///
  /// Known values: 正常, 已完成, 异常, 亏损, 已撤销, 进行中, 待处理.
  final String? status;

  /// Called when the chevron or card is tapped.
  final VoidCallback? onTap;

  /// Used to stagger entrance animation (index * 50ms delay).
  final int index;

  const RecordCard({
    super.key,
    required this.title,
    required this.detail,
    this.status,
    this.onTap,
    this.index = 0,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  double _animValue = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        setState(() => _animValue = 1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _animValue,
      duration: const Duration(milliseconds: 250),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 10.0, end: 0.0),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: child,
          );
        },
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surface,
        border: Border.all(color: AppDesignColors.borderMuted, width: 1),
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.all(AppRadii.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(),
                  const SizedBox(height: AppSpacing.xs),
                  _buildDetailLine(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildChevronButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Flexible(
          child: Text(
            widget.title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.status != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _buildStatusBadge(widget.status!),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = _StatusColors.forStatus(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.all(AppRadii.pill),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(color: colors.text),
      ),
    );
  }

  Widget _buildDetailLine() {
    return Text(
      widget.detail,
      style: AppTextStyles.body,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildChevronButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppDesignColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: widget.onTap,
        iconSize: 18,
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.chevron_right, color: AppDesignColors.textPrimary),
        splashRadius: 18,
      ),
    );
  }
}
