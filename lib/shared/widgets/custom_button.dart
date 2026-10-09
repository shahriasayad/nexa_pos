import 'package:flutter/material.dart';

enum CustomButtonVariant { primary, secondary, outline, text, danger }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final CustomButtonVariant variant;
  final EdgeInsetsGeometry padding;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = CustomButtonVariant.primary,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget child = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    switch (variant) {
      case CustomButtonVariant.secondary:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            padding: padding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case CustomButtonVariant.outline:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(padding: padding),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case CustomButtonVariant.text:
        return TextButton(
          style: TextButton.styleFrom(padding: padding),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case CustomButtonVariant.danger:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            padding: padding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case CustomButtonVariant.primary:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: padding,
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}
