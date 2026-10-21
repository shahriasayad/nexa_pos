import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';

enum BadgeType { success, warning, danger, info, neutral }

typedef StatusType = BadgeType;

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case BadgeType.success:
        bgColor = isDark
            ? AppColors.darkSuccess.withValues(alpha: 0.15)
            : AppColors.primarySoft;
        textColor = isDark ? AppColors.darkSuccess : AppColors.success;
        borderColor = isDark
            ? AppColors.darkSuccess.withValues(alpha: 0.3)
            : AppColors.success.withValues(alpha: 0.3);
        break;
      case BadgeType.warning:
        bgColor = AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.12);
        textColor = isDark ? AppColors.darkWarning : AppColors.warning;
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        break;
      case BadgeType.danger:
        bgColor = AppColors.danger.withValues(alpha: isDark ? 0.2 : 0.12);
        textColor = isDark ? AppColors.darkDanger : AppColors.danger;
        borderColor = AppColors.danger.withValues(alpha: 0.3);
        break;
      case BadgeType.info:
        bgColor = AppColors.info.withValues(alpha: isDark ? 0.2 : 0.12);
        textColor = isDark ? AppColors.darkInfo : AppColors.info;
        borderColor = AppColors.info.withValues(alpha: 0.3);
        break;
      case BadgeType.neutral:
        bgColor = isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
        textColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;
        borderColor = isDark ? AppColors.darkBorder : AppColors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
