import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';

class EmptyStateView extends StatelessWidget {
  final String? message;
  final String? title;
  final String? description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateView({
    super.key,
    this.message,
    this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  }) : assert(message != null || title != null, 'Either message or title must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayTitle = title ?? message ?? 'No records found';
    final displayDescription = description ?? (title != null ? message : null);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (displayDescription != null && displayDescription.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  displayDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                label: actionLabel!,
                icon: Icons.add,
                variant: CustomButtonVariant.primary,
                height: 38,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
