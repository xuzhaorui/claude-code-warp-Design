import 'package:flutter/material.dart';

import '../design/app_design_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

// ---- RecordCard-specific constants (not general Design.md tokens) ----

/// Animation and layout constants specific to RecordCard.
///
/// These derive from the Design.md Motion contract ("Lists may stagger at
/// index * 50ms") and from the web RecordCard visual proportions.
class _RC {
  _RC._();
  static const staggerMs = 50;
  static const animMs = 250;
  static const slidePx = 10.0;
  static const badgeVPad = 3.0;
  static const chevronSize = 36.0;
  static const chevronIcon = 18.0;
}

// ---- Status badge colors ----

/// Maps record status strings to badge colors using Design.md tokens /
/// theme colorScheme.
class _StatusColors {
  const _StatusColors({required this.bg, required this.fg});
  final Color bg;
  final Color fg;

  static const _neutral = _StatusColors(
    bg: AppDesignColors.surfaceMuted,
    fg: AppDesignColors.textSecondary,
  );
  static const _alert = _StatusColors(
    bg: AppDesignColors.primary,
    fg: AppDesignColors.textPrimary,
  );

  static _StatusColors forStatus(String status, ColorScheme cs) {
    switch (status) {
      case '异常':
      case '亏损':
        return _alert;
      case '已撤销':
        return _StatusColors(bg: cs.error, fg: AppDesignColors.scannerLight);
      default:
        return _neutral;
    }
  }
}

// ---- Public widget ----

/// A card showing a record title, detail line, optional status badge, and
/// a chevron tap target.  Maps to `src/components/Records/RecordCard.jsx`.
///
/// All colours, typography, spacing and radii come from Design.md tokens.
/// Animation constants (_RC) are component-local and documented in-line.
class RecordCard extends StatefulWidget {
  const RecordCard({
    super.key,
    required this.title,
    required this.detail,
    this.status,
    this.onTap,
    this.index = 0,
  });

  final String title;
  final String detail;
  final String? status;
  final VoidCallback? onTap;
  final int index;

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * _RC.staggerMs), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: _RC.animMs),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _RC.slidePx, end: 0.0),
        duration: const Duration(milliseconds: _RC.animMs),
        builder: (_, v, child) =>
            Transform.translate(offset: Offset(0, v), child: child),
        child: _card(context),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignColors.surface,
        border: Border.all(color: AppDesignColors.borderMuted),
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.all(AppRadii.md),
        child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_titleRow(context), const SizedBox(height: AppSpacing.xs), _detailLine()],
            )),
            const SizedBox(width: AppSpacing.md),
            _chevron(),
          ],
        ),
      ),
    );
  }

  Widget _titleRow(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(widget.title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (widget.status != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _badge(context, widget.status!),
        ],
      ],
    );
  }

  Widget _badge(BuildContext context, String status) {
    final c = _StatusColors.forStatus(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: _RC.badgeVPad),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.all(AppRadii.pill),
      ),
      child: Text(status, style: AppTextStyles.caption.copyWith(color: c.fg)),
    );
  }

  Widget _detailLine() => Text(widget.detail,
      style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis);

  Widget _chevron() => Container(
        width: _RC.chevronSize,
        height: _RC.chevronSize,
        decoration: const BoxDecoration(
          color: AppDesignColors.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: widget.onTap,
          iconSize: _RC.chevronIcon,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_right, color: AppDesignColors.textPrimary),
          splashRadius: _RC.chevronIcon,
        ),
      );
}
