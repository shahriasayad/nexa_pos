import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? width;
  final double? height;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      margin: EdgeInsets.zero,
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: card,
      );
    }

    return card;
  }
}
