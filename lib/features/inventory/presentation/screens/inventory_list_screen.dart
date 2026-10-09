import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../categories/data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_inventory_repository.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_details_screen.dart';

import '../../../../core/layout/app_shell.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  late InventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController(
      productRepo: MockProductRepository(),
      categoryRepo: MockCategoryRepository(),
      inventoryRepo: MockInventoryRepository(),
    );
    _controller.loadInventory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InventoryDetailsScreen(controller: _controller, product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Inventory',
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _controller.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_controller.errorMessage!)),
                );
                _controller.clearError();
              }
            });
          }

          switch (_controller.state) {
            case ViewState.initial:
            case ViewState.loading:
              return const LoadingView(message: 'Loading inventory...');
            case ViewState.error:
              return ErrorView(
                message: 'Failed to load',
                onRetry: _controller.loadInventory,
              );
            case ViewState.empty:
              return const EmptyStateView(
                message: 'No inventory found',
                icon: Icons.inventory_2_outlined,
              );
            case ViewState.success:
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: CustomCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (!ResponsiveLayout.isMobile(context))
                        _buildTableHeader(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _controller.products.length,
                          itemBuilder: (context, index) {
                            final product = _controller.products[index];
                            return _buildInventoryRow(product);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Product')),
          Expanded(flex: 1, child: _HeaderCell('Current Stock')),
          Expanded(flex: 1, child: _HeaderCell('Min Stock')),
          Expanded(flex: 1, child: _HeaderCell('Status')),
          Expanded(flex: 2, child: _HeaderCell('Last Movement')),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(Product product) {
    final lastMove = _controller.lastMovements[product.id];
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return InkWell(
        onTap: () => _navigateToDetails(product),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStockIndicator(product),
                  if (lastMove != null)
                    Text(
                      'Last: ${lastMove.type.name} (${lastMove.quantityChange > 0 ? '+' : ''}${lastMove.quantityChange})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _navigateToDetails(product),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
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
                  Text(
                    product.sku,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${product.stockQuantity}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${product.minimumStock}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(flex: 1, child: _buildStockIndicator(product)),
            Expanded(
              flex: 2,
              child: lastMove != null
                  ? Text(
                      '${lastMove.type.name} (${lastMove.quantityChange > 0 ? '+' : ''}${lastMove.quantityChange})',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    )
                  : Text(
                      'No movements',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockIndicator(Product product) {
    BadgeType badgeType;
    String label;

    switch (product.stockStatus) {
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

    return Align(
      alignment: Alignment.centerLeft,
      child: StatusBadge(label: label, type: badgeType),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
