import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';

enum BadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case BadgeType.success:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkSuccess : AppColors.success;
        break;
      case BadgeType.warning:
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkWarning : AppColors.warning;
        break;
      case BadgeType.danger:
        bgColor = AppColors.danger.withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkDanger : AppColors.danger;
        break;
      case BadgeType.info:
        bgColor = AppColors.info.withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkInfo : AppColors.info;
        break;
      case BadgeType.neutral:
        bgColor = isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
        textColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
