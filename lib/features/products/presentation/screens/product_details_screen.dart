import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';
import '../../../../core/layout/app_shell.dart';
import '../../domain/models/product.dart';
import 'product_form_screen.dart';
import '../controllers/product_controller.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final ProductController controller;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Product Details',
      actions: [
        CustomButton(
          label: 'Edit',
          icon: Icons.edit_outlined,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductFormScreen(
                  controller: controller,
                  productId: product.id,
                ),
              ),
            ).then((_) {
              if (context.mounted) {
                Navigator.pop(context);
              }
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          variant: CustomButtonVariant.outline,
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildInfoCard(context)),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 1, child: _buildPricingCard(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 40),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      'SKU: ${product.sku}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    StatusBadge(
                      label: product.isActive ? 'Active' : 'Inactive',
                      type: product.isActive ? BadgeType.success : BadgeType.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Inventory & Details'),
          _buildRow(context, 'Barcode', product.barcode?.isEmpty ?? true ? 'N/A' : product.barcode!),
          _buildRow(context, 'Category', product.categoryId),
          const Divider(),
          _buildRow(
            context,
            'Stock Status',
            product.stockStatus.name.toUpperCase(),
            valueColor: product.stockStatus == StockStatus.outOfStock
                ? AppColors.danger
                : product.stockStatus == StockStatus.lowStock
                    ? AppColors.warning
                    : AppColors.success,
          ),
          _buildRow(context, 'Stock Quantity', '${product.stockQuantity} ${product.unit}'),
          _buildRow(context, 'Minimum Stock', '${product.minimumStock} ${product.unit}'),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pricing'),
          _buildRow(context, 'Selling Price', '\$${product.sellingPrice.toStringAsFixed(2)}'),
          _buildRow(context, 'Purchase Price', '\$${product.purchasePrice.toStringAsFixed(2)}'),
          const Divider(),
          _buildRow(
            context,
            'Est. Margin',
            '\$${(product.sellingPrice - product.purchasePrice).toStringAsFixed(2)}',
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
