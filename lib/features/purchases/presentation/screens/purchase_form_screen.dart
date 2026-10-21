import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/purchases/data/repositories/mock_purchase_repository.dart';
import 'package:nexa_pos/features/purchases/domain/models/purchase_order.dart';
import 'package:nexa_pos/features/purchases/presentation/controllers/purchase_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';

class PurchaseFormScreen extends StatefulWidget {
  final PurchaseOrder? purchase;

  const PurchaseFormScreen({super.key, this.purchase});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  late PurchaseController _controller;
  final _productRepo = MockProductRepository();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<PurchaseItem> _items = [];
  String _supplierName = '';
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _catalogSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = PurchaseController(
      purchaseRepo: MockPurchaseRepository(),
      inventoryRepo: MockInventoryRepository(),
      productRepo: _productRepo,
    );
    if (widget.purchase != null) {
      _items = List.from(widget.purchase!.items);
      _supplierName = widget.purchase!.supplierName;
      _supplierController.text = _supplierName;
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _catalogSearchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getProducts();
    if (mounted) {
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.sku.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addItem(Product product) {
    setState(() {
      final existingIndex = _items.indexWhere((i) => i.productId == product.id);
      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + 1,
        );
      } else {
        _items.add(
          PurchaseItem(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitCost: product.purchasePrice,
          ),
        );
      }
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      setState(() => _items.removeAt(index));
    } else {
      setState(() {
        _items[index] = _items[index].copyWith(quantity: quantity);
      });
    }
  }

  void _saveDraft() async {
    _save(PurchaseStatus.draft);
  }

  void _placeOrder() async {
    _save(PurchaseStatus.ordered);
  }

  void _save(PurchaseStatus status) async {
    final supplier = _supplierController.text.trim();
    if (supplier.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Supplier name and at least one line item are required.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final totalAmount = _items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );

    final purchase = PurchaseOrder(
      id:
          widget.purchase?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      supplierId: widget.purchase?.supplierId ?? 'sup-manual',
      supplierName: supplier,
      status: status,
      items: _items,
      totalAmount: totalAmount,
      orderDate: widget.purchase?.orderDate ?? DateTime.now(),
    );

    final success = await _controller.savePurchase(purchase);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.purchase != null;
    final totalAmount = _items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      currentRoute: AppRoutes.purchases,
      title: isEditing ? 'Edit Purchase Order' : 'New Purchase Order',
      actions: [
        CustomButton(
          label: 'Save Draft',
          icon: Icons.save_outlined,
          variant: CustomButtonVariant.outline,
          height: 38,
          onPressed: _saveDraft,
        ),
        const SizedBox(width: AppSpacing.sm),
        CustomButton(
          label: 'Place Order',
          icon: Icons.send_rounded,
          variant: CustomButtonVariant.primary,
          height: 38,
          onPressed: _placeOrder,
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPageHeader(
                  title: isEditing ? 'Edit Purchase Order' : 'Create Purchase Order',
                  subtitle:
                      'Select products to restock, verify procurement unit costs, and send to vendor.',
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: PO Order Sheet (60%)
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildSupplierCard(isDark),
                            const SizedBox(height: AppSpacing.md),
                            _buildItemsCard(isDark),
                            const SizedBox(height: AppSpacing.md),
                            _buildTotalCard(totalAmount, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // Right: Product Catalog Picker (40%)
                      Expanded(
                        flex: 4,
                        child: _buildCatalogPicker(isDark),
                      ),
                    ],
                  )
                else ...[
                  // Mobile stacked layout
                  _buildSupplierCard(isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildCatalogPicker(isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildItemsCard(isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildTotalCard(totalAmount, isDark),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierCard(bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Vendor & Order Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _supplierController,
            decoration: const InputDecoration(
              labelText: 'Supplier Name *',
              hintText: 'Enter vendor name e.g. Acme Beverage Co.',
              prefixIcon: Icon(Icons.storefront_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Order Line Items (${_items.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_items.fold<int>(0, (sum, i) => sum + i.quantity)} units total',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyStateView(
                icon: Icons.add_shopping_cart_outlined,
                title: 'No Items Added',
                description:
                    'Select products from the catalog panel to add them to this purchase order.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unit cost: \$${item.unitCost.toStringAsFixed(2)}  •  Subtotal: \$${item.lineTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Stepper
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceMuted
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.normal),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  _updateQuantity(index, item.quantity - 1),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 28),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  _updateQuantity(index, item.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.danger),
                        tooltip: 'Remove',
                        onPressed: () => _updateQuantity(index, 0),
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

  Widget _buildTotalCard(double totalAmount, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Purchase Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Save Draft',
                  icon: Icons.save_outlined,
                  variant: CustomButtonVariant.outline,
                  height: 42,
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton(
                  label: 'Place Order',
                  icon: Icons.send_rounded,
                  variant: CustomButtonVariant.primary,
                  height: 42,
                  onPressed: _placeOrder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogPicker(bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Product Catalog',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _catalogSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Search products by name or SKU...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: _filterProducts,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: _filteredProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No matching products found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final inCart = _items.any((i) => i.productId == product.id);

                      return ListTile(
                        dense: true,
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Cost: \$${product.purchasePrice.toStringAsFixed(2)}  •  Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            inCart
                                ? Icons.add_circle
                                : Icons.add_circle_outline,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          onPressed: () => _addItem(product),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
