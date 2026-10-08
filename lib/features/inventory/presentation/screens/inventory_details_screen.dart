import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';
import '../../../../core/layout/app_shell.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/models/stock_movement.dart';
import '../controllers/inventory_controller.dart';
import 'stock_adjustment_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  void _loadMovements() {
    _movementsFuture = widget.controller.getProductMovements(widget.product.id);
  }

  void _showAdjustStockDialog() {
    showDialog(
      context: context,
      builder: (_) => StockAdjustmentDialog(
        product: widget.product,
        controller: widget.controller,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadMovements();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Inventory Details',
      actions: [
        CustomButton(
          label: 'Adjust Stock',
          icon: Icons.edit_note,
          onPressed: _showAdjustStockDialog,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          variant: CustomButtonVariant.outline,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Movement History'),
            Expanded(
              child: CustomCard(
                padding: EdgeInsets.zero,
                child: FutureBuilder<List<StockMovement>>(
                  future: _movementsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Failed to load history'));
                    }
                    final movements = snapshot.data ?? [];
                    if (movements.isEmpty) {
                      return const Center(child: Text('No stock movements found.'));
                    }
                    return ListView.separated(
                      itemCount: movements.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = movements[index];
                        final isPositive = m.quantityChange > 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Icon(
                                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 20,
                                  color: isPositive ? AppColors.success : AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.type.name.toUpperCase()} - ${m.reason}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${m.timestamp.toString().split('.')[0]}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (m.note != null && m.note!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Note: ${m.note}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                '${isPositive ? '+' : ''}${m.quantityChange}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    BadgeType badgeType;
    String label;
    switch (widget.product.stockStatus) {
      case StockStatus.inStock:
        badgeType = BadgeType.success;
        label = 'In Stock';
        break;
      case StockStatus.lowStock:
        badgeType = BadgeType.warning;
        label = 'Low Stock';
        break;
      case StockStatus.outOfStock:
        badgeType = BadgeType.danger;
        label = 'Out of Stock';
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
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'SKU: ${widget.product.sku}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              StatusBadge(label: label, type: badgeType),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Current Stock', '${widget.product.stockQuantity}', context),
              _buildMetric('Minimum Stock', '${widget.product.minimumStock}', context),
              _buildMetric('Unit', widget.product.unit, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
