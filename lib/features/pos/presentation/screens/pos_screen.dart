import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/customers/domain/models/customer.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/pos_controller.dart';
import 'package:nexa_pos/features/pos/presentation/screens/checkout_dialog.dart';
import 'package:nexa_pos/features/pos/presentation/screens/customer_selection_dialog.dart';
import 'package:nexa_pos/features/pos/presentation/screens/receipt_dialog.dart';
import 'package:nexa_pos/features/pos/presentation/screens/widgets/cart_panel.dart';
import 'package:nexa_pos/features/pos/presentation/screens/widgets/product_list_panel.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with SingleTickerProviderStateMixin {
  late PosController _controller;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = PosController(
      productRepo: AppRepositories.instance.productRepo,
      inventoryRepo: AppRepositories.instance.inventoryRepo,
      salesRepo: AppRepositories.instance.salesRepo,
      customerRepo: AppRepositories.instance.customerRepo,
    );
    _controller.searchProducts(null);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showCheckout() async {
    if (_controller.cart.isEmpty) return;
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CheckoutDialog(controller: _controller),
    );
    if (success == true && _controller.lastCompletedSale != null && mounted) {
      showDialog(
        context: context,
        builder: (_) => ReceiptDialog(sale: _controller.lastCompletedSale!),
      );
    }
  }

  void _showCustomerSelection() async {
    final result = await showDialog(
      context: context,
      builder: (_) => const CustomerSelectionDialog(),
    );
    if (result == 'clear') {
      _controller.setCustomer(null);
    } else if (result is Customer) {
      _controller.setCustomer(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Point of Sale',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          tooltip: 'Select Customer',
          onPressed: _showCustomerSelection,
        ),
        if (_controller.cart.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Cart',
            onPressed: _controller.clearCart,
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

          return ResponsiveLayout(
            mobile: _buildMobileLayout(),
            tablet: _buildDesktopLayout(),
            desktop: _buildDesktopLayout(),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    final totalItemsCount =
        _controller.cart.fold<int>(0, (sum, item) => sum + item.quantity);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Mobile Tab Bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              const Tab(
                icon: Icon(Icons.grid_view_outlined, size: 20),
                text: 'Catalog',
              ),
              Tab(
                icon: Badge(
                  isLabelVisible: totalItemsCount > 0,
                  label: Text('$totalItemsCount'),
                  child: const Icon(Icons.shopping_cart_outlined, size: 20),
                ),
                text: 'Cart (${_controller.cart.length})',
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Catalog
              Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: _controller.cart.isNotEmpty ? 64.0 : 0.0,
                      ),
                      child: _buildProductList(),
                    ),
                  ),
                  // Sticky bottom bar when items in cart
                  if (_controller.cart.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, -2),
                              blurRadius: 8,
                            ),
                          ],
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$totalItemsCount items in cart',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  '\$${_controller.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _tabController.animateTo(1);
                              },
                              icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                              label: const Text('View Cart'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Tab 2: Cart Panel
              _buildCartPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Left main workspace: Products Catalog (flex: 3)
        Expanded(
          flex: 3,
          child: _buildProductList(),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),

        // Right workspace: Dedicated Checkout Panel (flex: 2)
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 460),
          child: SizedBox(
            width: 380,
            child: _buildCartPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return ProductListPanel(
      controller: _controller,
      searchController: _searchController,
    );
  }

  Widget _buildCartPanel() {
    return CartPanel(
      controller: _controller,
      onShowCustomerSelection: _showCustomerSelection,
      onShowCheckout: _showCheckout,
    );
  }
}
