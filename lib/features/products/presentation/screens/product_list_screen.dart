import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../domain/models/product.dart';
import '../controllers/product_controller.dart';
import '../../data/repositories/mock_product_repository.dart';
import '../../../categories/data/repositories/mock_category_repository.dart';
import 'product_form_screen.dart';
import 'product_details_screen.dart';

import '../../../../core/layout/app_drawer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ProductController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductController(
      productRepo: MockProductRepository(),
      categoryRepo: MockCategoryRepository(),
    );
    _controller.loadProducts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToForm([String? productId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          controller: _controller,
          productId: productId,
        ),
      ),
    );
  }

  void _navigateToDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          controller: _controller,
          product: product,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    _controller.setSearch(val);
                  },
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            hint: const Text('Category'),
                            value: _controller.selectedCategoryId,
                            onChanged: (val) => _controller.setCategory(val),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Categories')),
                              ..._controller.categories.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                            ],
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<StockStatus>(
                            hint: const Text('Stock Status'),
                            value: _controller.selectedStockStatus,
                            onChanged: (val) => _controller.setStockStatus(val),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Stock')),
                              ...StockStatus.values.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              )),
                            ],
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<bool>(
                            hint: const Text('Status'),
                            value: _controller.isActiveFilter,
                            onChanged: (val) => _controller.setActiveFilter(val),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Status')),
                              DropdownMenuItem(value: true, child: Text('Active')),
                              DropdownMenuItem(value: false, child: Text('Inactive')),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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

          switch (_controller.state) {
            case ViewState.initial:
            case ViewState.loading:
              return const LoadingView(message: 'Loading products...');
            case ViewState.error:
              return ErrorView(
                message: 'Failed to load',
                onRetry: _controller.loadProducts,
              );
            case ViewState.empty:
              return EmptyStateView(
                message: 'No products found',
                icon: Icons.inventory_2_outlined,
                actionLabel: 'Add Product',
                onAction: _navigateToForm,
              );
            case ViewState.success:
              return ListView.builder(
                itemCount: _controller.products.length,
                itemBuilder: (context, index) {
                  final product = _controller.products[index];
                  final isLowStock = product.stockStatus != StockStatus.inStock;
                  return ListTile(
                    onTap: () => _navigateToDetails(product),
                    title: Text(product.name),
                    subtitle: Text('SKU: ${product.sku} | Price: \$${product.sellingPrice.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLowStock)
                          Icon(
                            product.stockStatus == StockStatus.outOfStock ? Icons.error : Icons.warning,
                            color: product.stockStatus == StockStatus.outOfStock ? Colors.red : Colors.orange,
                          ),
                        const SizedBox(width: 8),
                        Text('Stock: ${product.stockQuantity}', 
                          style: TextStyle(
                            color: product.stockStatus == StockStatus.outOfStock ? Colors.red : null,
                            fontWeight: isLowStock ? FontWeight.bold : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navigateToForm(product.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _controller.deleteProduct(product.id),
                        ),
                      ],
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
