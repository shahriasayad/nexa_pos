import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../controllers/product_controller.dart';
import '../../data/repositories/mock_product_repository.dart';
import '../../../categories/data/repositories/mock_category_repository.dart';
import 'product_form_screen.dart';

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
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) {
                      _controller.setSearch(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return DropdownButton<String>(
                      hint: const Text('All Categories'),
                      value: _controller.selectedCategoryId,
                      onChanged: (val) => _controller.setCategory(val),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ..._controller.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                      ],
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
                  final isLowStock = product.stockQuantity <= product.minimumStock;
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('SKU: ${product.sku} | Price: \$${product.sellingPrice.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLowStock)
                          const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Stock: ${product.stockQuantity}', 
                          style: TextStyle(
                            color: product.stockQuantity == 0 ? Colors.red : null,
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
