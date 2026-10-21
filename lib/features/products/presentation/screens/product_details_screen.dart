import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/products/presentation/controllers/product_controller.dart';
import 'package:nexa_pos/features/products/presentation/screens/product_form_screen.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profitMargin = product.sellingPrice > 0
        ? ((product.sellingPrice - product.purchasePrice) /
            product.sellingPrice *
            100)
        : 0.0;

    return AppShell(
      title: 'Product Details',
      showBottomNav: false,
      actions: [
        CustomButton(
          label: 'Edit Product',
          icon: Icons.edit_outlined,
          variant: CustomButtonVariant.outline,
          height: 38,
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
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                CustomCard(
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceMuted
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: isDark
                              ? AppColors.darkSuccess
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                StatusBadge(
                                  label: product.isActive ? 'Active' : 'Inactive',
                                  type: product.isActive
                                      ? BadgeType.success
                                      : BadgeType.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${product.sku} • Category: ${product.categoryId}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2 Column details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inventory Status Card
                    Expanded(
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Inventory Status'),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDataRow(
                              'Current Stock',
                              '${product.stockQuantity} ${product.unit}',
                              isDark,
                              valueStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildDataRow(
                              'Minimum Alert Threshold',
                              '${product.minimumStock} ${product.unit}',
                              isDark,
                            ),
                            _buildDataRow(
                              'Status',
                              product.stockStatus.name.toUpperCase(),
                              isDark,
                              valueColor: product.stockStatus ==
                                      StockStatus.outOfStock
                                  ? AppColors.danger
                                  : (product.stockStatus == StockStatus.lowStock
                                      ? AppColors.warning
                                      : AppColors.success),
                            ),
                            _buildDataRow(
                              'Barcode',
                              product.barcode?.isNotEmpty == true
                                  ? product.barcode!
                                  : 'Not assigned',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),

                    // Pricing & Financial Card
                    Expanded(
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Pricing & Valuation'),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDataRow(
                              'Selling Price',
                              '\$${product.sellingPrice.toStringAsFixed(2)}',
                              isDark,
                              valueStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            _buildDataRow(
                              'Purchase Cost',
                              '\$${product.purchasePrice.toStringAsFixed(2)}',
                              isDark,
                            ),
                            _buildDataRow(
                              'Unit Margin',
                              '\$${(product.sellingPrice - product.purchasePrice).toStringAsFixed(2)} (${profitMargin.toStringAsFixed(1)}%)',
                              isDark,
                              valueColor: profitMargin >= 20
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            _buildDataRow(
                              'Stock Valuation',
                              '\$${(product.stockQuantity * product.purchasePrice).toStringAsFixed(2)}',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
          ),
        ],
      ),
    );
  }
}
