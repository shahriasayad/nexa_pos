import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/inventory/domain/models/stock_movement.dart';
import 'package:nexa_pos/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:nexa_pos/features/inventory/presentation/screens/stock_adjustment_dialog.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class InventoryDetailsScreen extends StatefulWidget {
  final Product product;
  final InventoryController controller;

  const InventoryDetailsScreen({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  late Future<List<StockMovement>> _movementsFuture;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _loadMovements();
  }

  void _loadMovements() {
    _movementsFuture = widget.controller.getProductMovements(_currentProduct.id);
  }

  void _showAdjustStockDialog() {
    showDialog(
      context: context,
      builder: (_) => StockAdjustmentDialog(
        product: _currentProduct,
        controller: widget.controller,
      ),
    ).then((_) async {
      if (mounted) {
        final updated = await widget.controller.productRepo
            .getProductById(_currentProduct.id);
        if (mounted) {
          setState(() {
            if (updated != null) _currentProduct = updated;
            _loadMovements();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Inventory Details',
      showBottomNav: false,
      actions: [
        CustomButton(
          label: 'Adjust Stock',
          icon: Icons.edit_note,
          height: 38,
          onPressed: _showAdjustStockDialog,
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
                _buildSummaryCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildMovementHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    BadgeType badgeType;
    String label;
    IconData icon;
    switch (_currentProduct.stockStatus) {
      case StockStatus.inStock:
        badgeType = BadgeType.success;
        label = 'In Stock';
        icon = Icons.check_circle_outline;
        break;
      case StockStatus.lowStock:
        badgeType = BadgeType.warning;
        label = 'Low Stock';
        icon = Icons.warning_amber_rounded;
        break;
      case StockStatus.outOfStock:
        badgeType = BadgeType.danger;
        label = 'Out of Stock';
        icon = Icons.cancel_outlined;
        break;
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentProduct.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${_currentProduct.sku} • Category: ${_currentProduct.categoryId}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              StatusBadge(label: label, type: badgeType, icon: icon),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                'Current Stock',
                '${_currentProduct.stockQuantity}',
                _currentProduct.stockStatus == StockStatus.outOfStock
                    ? AppColors.danger
                    : AppColors.primary,
                context,
              ),
              _buildMetric(
                'Minimum Stock',
                '${_currentProduct.minimumStock}',
                isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                context,
              ),
              _buildMetric(
                'Unit of Measure',
                _currentProduct.unit,
                isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                context,
              ),
              _buildMetric(
                'Stock Valuation',
                '\$${(_currentProduct.stockQuantity * _currentProduct.purchasePrice).toStringAsFixed(2)}',
                isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SectionHeader(title: 'Stock Movement Audit History'),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          FutureBuilder<List<StockMovement>>(
            future: _movementsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Failed to load history')),
                );
              }
              final movements = snapshot.data ?? [];
              if (movements.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 32,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No stock movements recorded yet for this product.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movements.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final m = movements[index];
                  final isPositive = m.quantityChange > 0;
                  final timeStr = m.timestamp.toString().split('.')[0];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPositive
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 18,
                            color: isPositive ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.type.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${m.reason}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$timeStr  |  Prev: ${m.previousStock} -> New: ${m.newStock}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                              ),
                              if (m.note != null && m.note!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Note: ${m.note}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${m.quantityChange}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isPositive ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    Color valueColor,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
