import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

import '../../domain/models/product_summary.dart';

class TopProductsList extends StatelessWidget {
  final String title;
  final List<ProductSummary> products;
  final bool isLowStock;

  const TopProductsList({
    super.key,
    required this.title,
    required this.products,
    this.isLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  isLowStock ? Icons.warning_amber_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: isLowStock ? AppColors.warning : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (products.isNotEmpty)
                  Text(
                    '${products.length} items',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLowStock ? Icons.check_circle_outline : Icons.inventory_2_outlined,
                      size: 28,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isLowStock ? 'No low stock warnings' : 'No items sold yet',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceMuted
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${product.price.toStringAsFixed(2)} each',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (isLowStock)
                        StatusBadge(
                          label: '${product.stockQuantity} in stock',
                          type: product.stockQuantity == 0
                              ? BadgeType.danger
                              : BadgeType.warning,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceMuted
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${product.soldQuantity} sold',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
