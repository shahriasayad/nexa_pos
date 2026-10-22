import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final String? categoryName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListTile({
    super.key,
    required this.product,
    this.categoryName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: isMobile ? _buildMobileRow(context) : _buildDesktopRow(context),
      ),
    );
  }

  Widget _buildDesktopRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Product name & SKU with thumbnail
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceMuted
                      : AppColors.primarySoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: isDark ? AppColors.darkSuccess : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${product.sku}',
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
            ],
          ),
        ),

        // Category
        Expanded(
          flex: 2,
          child: Text(
            categoryName ?? (product.categoryId.isNotEmpty ? 'Category #${product.categoryId}' : '—'),
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),

        // Selling Price
        Expanded(
          flex: 1,
          child: Text(
            '\$${product.sellingPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.primary,
            ),
          ),
        ),

        // Cost Price
        Expanded(
          flex: 1,
          child: Text(
            '\$${product.purchasePrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ),

        // Stock Level with Status
        Expanded(
          flex: 1,
          child: _buildStockIndicator(context),
        ),

        // Active Status
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: product.isActive ? 'Active' : 'Inactive',
              type: product.isActive ? BadgeType.success : BadgeType.neutral,
            ),
          ),
        ),

        // Action Buttons
        SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                tooltip: 'Edit Product',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                onPressed: onDelete,
                tooltip: 'Delete Product',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.primarySoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: isDark ? AppColors.darkSuccess : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku} • Category: ${product.categoryId}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${product.sellingPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildStockIndicator(context),
                const SizedBox(width: AppSpacing.md),
                StatusBadge(
                  label: product.isActive ? 'Active' : 'Inactive',
                  type: product.isActive ? BadgeType.success : BadgeType.neutral,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockIndicator(BuildContext context) {
    Color dotColor;
    String statusText;

    switch (product.stockStatus) {
      case StockStatus.inStock:
        dotColor = AppColors.success;
        statusText = '${product.stockQuantity}';
        break;
      case StockStatus.lowStock:
        dotColor = AppColors.warning;
        statusText = '${product.stockQuantity} (Low)';
        break;
      case StockStatus.outOfStock:
        dotColor = AppColors.danger;
        statusText = '0 (Out)';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: product.stockStatus != StockStatus.inStock
                ? FontWeight.bold
                : FontWeight.w500,
            color: product.stockStatus == StockStatus.outOfStock
                ? AppColors.danger
                : null,
          ),
        ),
      ],
    );
  }
}
