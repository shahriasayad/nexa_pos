import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

import '../../../domain/models/product.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ResponsiveLayout.isMobile(context)
            ? _buildMobileRow(context)
            : _buildDesktopRow(context),
      ),
    );
  }

  Widget _buildDesktopRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(product.sku, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            product.categoryId,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '\$${product.sellingPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '\$${product.purchasePrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(flex: 1, child: _buildStockIndicator(context)),
        Expanded(
          flex: 1,
          child: StatusBadge(
            label: product.isActive ? 'Active' : 'Inactive',
            type: product.isActive ? BadgeType.success : BadgeType.neutral,
          ),
        ),
        _buildActions(),
      ],
    );
  }

  Widget _buildMobileRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'SKU: ${product.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '\$${product.sellingPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStockIndicator(context),
            StatusBadge(
              label: product.isActive ? 'Active' : 'Inactive',
              type: product.isActive ? BadgeType.success : BadgeType.neutral,
            ),
            _buildActions(),
          ],
        ),
      ],
    );
  }

  Widget _buildStockIndicator(BuildContext context) {
    Color stockColor;
    switch (product.stockStatus) {
      case StockStatus.inStock:
        stockColor = AppColors.success;
        break;
      case StockStatus.lowStock:
        stockColor = AppColors.warning;
        break;
      case StockStatus.outOfStock:
        stockColor = AppColors.danger;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: stockColor),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${product.stockQuantity}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: product.stockStatus != StockStatus.inStock
                ? FontWeight.bold
                : FontWeight.normal,
            color: product.stockStatus == StockStatus.outOfStock
                ? AppColors.danger
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          tooltip: 'Edit Product',
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            size: 20,
            color: AppColors.danger,
          ),
          onPressed: onDelete,
          tooltip: 'Delete Product',
        ),
      ],
    );
  }
}
