import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/categories/data/repositories/mock_category_repository.dart';
import 'package:nexa_pos/features/categories/domain/models/category.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/pos_controller.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class ProductListPanel extends StatefulWidget {
  final PosController controller;
  final TextEditingController searchController;

  const ProductListPanel({
    super.key,
    required this.controller,
    required this.searchController,
  });

  @override
  State<ProductListPanel> createState() => _ProductListPanelState();
}

class _ProductListPanelState extends State<ProductListPanel> {
  List<Category> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await MockCategoryRepository().getCategories();
    if (mounted) {
      setState(() {
        _categories = categories.where((c) => c.isActive).toList();
      });
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    widget.controller.searchProducts(
      widget.searchController.text.trim().isEmpty
          ? null
          : widget.searchController.text.trim(),
      category: categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search & Scan Bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: widget.searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products by name, SKU, or barcode...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: widget.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.controller.searchProducts(
                                  null,
                                  category: _selectedCategoryId,
                                );
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceMuted
                          : AppColors.surfaceMuted,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.normal),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.normal),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      widget.controller.searchProducts(
                        val.trim().isEmpty ? null : val.trim(),
                        category: _selectedCategoryId,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Barcode scan indicator button
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceMuted
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.normal),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  tooltip: 'Barcode Scanner Ready',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Barcode scanner ready for input'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Category Filter Chips
        if (_categories.isNotEmpty)
          Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs, top: 6, bottom: 6),
                  child: FilterChip(
                    label: const Text('All Categories'),
                    selected: _selectedCategoryId == null,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedCategoryId == null
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    onSelected: (_) => _onCategorySelected(null),
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs, top: 6, bottom: 6),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => _onCategorySelected(cat.id),
                    ),
                  );
                }),
              ],
            ),
          ),

        // Product Catalog Grid
        Expanded(
          child: widget.controller.searchResults.isEmpty
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    message: 'No available products found',
                    actionLabel: _selectedCategoryId != null ||
                            widget.searchController.text.isNotEmpty
                        ? 'Clear Filters'
                        : null,
                    onAction: () {
                      widget.searchController.clear();
                      _onCategorySelected(null);
                    },
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: widget.controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final product = widget.controller.searchResults[index];
                    return _buildProductCard(context, product, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    bool isDark,
  ) {
    // Check if item is already in cart
    final cartItemIndex = widget.controller.cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    final inCartQty =
        cartItemIndex >= 0 ? widget.controller.cart[cartItemIndex].quantity : 0;

    final isLowStock = product.stockQuantity <= product.minimumStock;

    return CustomCard(
      padding: EdgeInsets.zero,
      onTap: () => widget.controller.addToCart(product),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon / thumbnail area
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceMuted
                          : AppColors.primarySoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 26,
                      color: isDark ? AppColors.darkSuccess : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Name
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),

                // SKU
                Text(
                  'SKU: ${product.sku}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),

                const Spacer(),

                // Price and Stock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    StatusBadge(
                      label: '${product.stockQuantity}',
                      type: isLowStock ? BadgeType.warning : BadgeType.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // In-Cart Indicator Badge
          if (inCartQty > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$inCartQty in cart',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
