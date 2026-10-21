import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';

enum CustomButtonVariant { primary, secondary, outline, text, danger }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final CustomButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool isFullWidth;
  final bool? fullWidth;
  final double? fontSize;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = CustomButtonVariant.primary,
    this.padding,
    this.height = 42,
    this.isFullWidth = false,
    this.fullWidth,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final defaultPadding = padding ??
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0);

    Widget content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == CustomButtonVariant.outline ||
                        variant == CustomButtonVariant.text
                    ? colorScheme.primary
                    : AppColors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize ?? 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.normal),
    );

    Widget button;
    switch (variant) {
      case CustomButtonVariant.secondary:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            elevation: 0,
            shape: roundedShape,
            padding: defaultPadding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
      case CustomButtonVariant.outline:
        button = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            shape: roundedShape,
            padding: defaultPadding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
      case CustomButtonVariant.text:
        button = TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            shape: roundedShape,
            padding: defaultPadding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
      case CustomButtonVariant.danger:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: roundedShape,
            padding: defaultPadding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
      case CustomButtonVariant.primary:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: roundedShape,
            padding: defaultPadding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
    }

    final effectiveFullWidth = fullWidth ?? isFullWidth;
    if (height != null) {
      button = SizedBox(
        height: height,
        width: effectiveFullWidth ? double.infinity : null,
        child: button,
      );
    } else if (effectiveFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
