import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:nexa_pos/features/inventory/presentation/screens/inventory_details_screen.dart';
import 'package:nexa_pos/features/inventory/presentation/screens/stock_adjustment_dialog.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  late InventoryController _controller;
  final TextEditingController _searchController = TextEditingController();
  StockStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController(
      productRepo: AppRepositories.instance.productRepo,
      categoryRepo: AppRepositories.instance.categoryRepo,
      inventoryRepo: AppRepositories.instance.inventoryRepo,
    );
    _controller.loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    ).then((_) {
      if (mounted) _controller.loadInventory();
    });
  }

  void _showAdjustStockDialog(Product product) {
    showDialog(
      context: context,
      builder: (_) => StockAdjustmentDialog(
        product: product,
        controller: _controller,
      ),
    ).then((_) {
      if (mounted) _controller.loadInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Inventory',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Inventory',
          onPressed: _controller.loadInventory,
        ),
      ],
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _controller.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_controller.errorMessage!),
                    backgroundColor: AppColors.danger,
                  ),
                );
                _controller.clearError();
              }
            });
          }

          switch (_controller.state) {
            case ViewState.initial:
            case ViewState.loading:
              return const LoadingView(message: 'Loading inventory data...');
            case ViewState.error:
              return ErrorView(
                message: _controller.errorMessage ?? 'Failed to load inventory',
                onRetry: _controller.loadInventory,
              );
            case ViewState.empty:
              return const EmptyStateView(
                message: 'No inventory items tracked',
                icon: Icons.warehouse_outlined,
              );
            case ViewState.success:
              return _buildContent(context);
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final products = _controller.products;
    final totalSkus = products.length;
    final inStock = products.where((p) => p.stockStatus == StockStatus.inStock).length;
    final lowStock = products.where((p) => p.stockStatus == StockStatus.lowStock).length;
    final outOfStock = products.where((p) => p.stockStatus == StockStatus.outOfStock).length;

    // Filtered items
    final query = _searchController.text.trim().toLowerCase();
    final filtered = products.where((p) {
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
      final matchesStatus = _filterStatus == null || p.stockStatus == _filterStatus;
      return matchesQuery && matchesStatus;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Metric Summary Bar
          _buildKpiBanner(totalSkus, inStock, lowStock, outOfStock),
          const SizedBox(height: AppSpacing.md),

          // Search and Filter Bar
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.md),

          // Inventory Table / List
          Expanded(
            child: CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (!ResponsiveLayout.isMobile(context)) _buildTableHeader(),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: Text('No inventory items match filter'),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Theme.of(context).dividerTheme.color,
                            ),
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              return _buildInventoryRow(product);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBanner(int total, int inStock, int lowStock, int outOfStock) {
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricTile('Total Tracked', '$total', AppColors.info)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildMetricTile('In Stock', '$inStock', AppColors.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Low Stock Alerts', '$lowStock', AppColors.warning)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildMetricTile('Out of Stock', '$outOfStock', AppColors.danger)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildMetricTile('Total Tracked SKUs', '$total', AppColors.info)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildMetricTile('In Stock', '$inStock', AppColors.success)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildMetricTile('Low Stock Alerts', '$lowStock', AppColors.warning)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildMetricTile('Out of Stock', '$outOfStock', AppColors.danger)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search inventory by name or SKU...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.normal),
            color: isDark ? AppColors.darkSurface : AppColors.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StockStatus?>(
              value: _filterStatus,
              hint: const Text('All Statuses', style: TextStyle(fontSize: 12.5)),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ...StockStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())),
                ),
              ],
              onChanged: (val) => setState(() => _filterStatus = val),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('PRODUCT')),
          Expanded(flex: 1, child: _HeaderCell('STOCK LEVEL')),
          Expanded(flex: 1, child: _HeaderCell('MIN THRESHOLD')),
          Expanded(flex: 1, child: _HeaderCell('STATUS')),
          Expanded(flex: 2, child: _HeaderCell('LAST MOVEMENT')),
          SizedBox(width: 90, child: _HeaderCell('ACTION', alignment: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(Product product) {
    final lastMove = _controller.lastMovements[product.id];
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMobile) {
      return InkWell(
        onTap: () => _navigateToDetails(product),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStockBadge(product),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock: ${product.stockQuantity} (Min: ${product.minimumStock})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAdjustStockDialog(product),
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Adjust', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.warehouse_outlined, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.sku,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${product.stockQuantity} ${product.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${product.minimumStock} ${product.unit}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStockBadge(product),
              ),
            ),
            Expanded(
              flex: 2,
              child: lastMove != null
                  ? Text(
                      '${lastMove.type.name.toUpperCase()} (${lastMove.quantityChange > 0 ? '+' : ''}${lastMove.quantityChange})',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    )
                  : Text(
                      'No movements',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
            ),
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showAdjustStockDialog(product),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Adjust', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(Product product) {
    switch (product.stockStatus) {
      case StockStatus.inStock:
        return const StatusBadge(
          label: 'In Stock',
          type: BadgeType.success,
          icon: Icons.check_circle_outline,
        );
      case StockStatus.lowStock:
        return const StatusBadge(
          label: 'Low Stock',
          type: BadgeType.warning,
          icon: Icons.warning_amber_rounded,
        );
      case StockStatus.outOfStock:
        return const StatusBadge(
          label: 'Out of Stock',
          type: BadgeType.danger,
          icon: Icons.cancel_outlined,
        );
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign alignment;

  const _HeaderCell(this.text, {this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      textAlign: alignment,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }
}
