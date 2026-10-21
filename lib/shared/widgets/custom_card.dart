import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? width;
  final double? height;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final double elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.color,
    this.width,
    this.height,
    this.border,
    this.borderRadius,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    final card = Card(
      color: color,
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveRadius,
        side: border ??
            BorderSide(
              color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE2E8E4),
              width: 1,
            ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: card,
      );
    }

    return card;
  }
}
