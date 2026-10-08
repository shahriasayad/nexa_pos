import 'package:flutter/material.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../inventory/data/repositories/mock_inventory_repository.dart';
import '../../data/repositories/mock_sales_repository.dart';
import '../../../customers/data/repositories/mock_customer_repository.dart';
import '../controllers/pos_controller.dart';
import 'checkout_dialog.dart';
import 'receipt_dialog.dart';
import 'customer_selection_dialog.dart';
import '../../../../core/layout/app_drawer.dart';
import '../../../customers/domain/models/customer.dart';
import 'widgets/product_list_panel.dart';
import 'widgets/cart_panel.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late PosController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = PosController(
      productRepo: MockProductRepository(),
      inventoryRepo: MockInventoryRepository(),
      salesRepo: MockSalesRepository(),
      customerRepo: MockCustomerRepository(),
    );
    _controller.searchProducts(null);
  }

  @override
  void dispose() {
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
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Point of Sale'),
      ),
      body: ListenableBuilder(
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
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Cart'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductList(),
                _buildCartPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildProductList(),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: _buildCartPanel(),
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
