import 'package:flutter/material.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../inventory/data/repositories/mock_inventory_repository.dart';
import '../../data/repositories/mock_sales_repository.dart';
import '../controllers/pos_controller.dart';
import 'checkout_dialog.dart';
import 'receipt_dialog.dart';
import '../../../../core/layout/app_drawer.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search products by name/SKU/barcode...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => _controller.searchProducts(val),
          ),
        ),
        Expanded(
          child: _controller.searchResults.isEmpty
              ? const Center(child: Text('No products found or available in stock.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final product = _controller.searchResults[index];
                    return Card(
                      child: InkWell(
                        onTap: () => _controller.addToCart(product),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(product.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('\$${product.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 16)),
                              const Spacer(),
                              Text('Stock: ${product.stockQuantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: const Row(
            children: [
              Icon(Icons.shopping_cart),
              SizedBox(width: 8),
              Text('Current Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _controller.cart.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView.builder(
                  itemCount: _controller.cart.length,
                  itemBuilder: (context, index) {
                    final item = _controller.cart[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('\$${item.product.sellingPrice.toStringAsFixed(2)} x ${item.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _controller.updateQuantity(item.product, item.quantity - 1),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _controller.addToCart(item.product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _controller.removeFromCart(item.product),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                  Text('\$${_controller.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('\$${_controller.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _controller.cart.isEmpty ? null : _controller.clearCart,
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _controller.cart.isEmpty ? null : _showCheckout,
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
