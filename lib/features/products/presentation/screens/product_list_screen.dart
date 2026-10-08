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
import 'widgets/product_filter_bar.dart';
import 'widgets/product_list_tile.dart';

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
        bottom: ProductFilterBar(controller: _controller),
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
                  return ProductListTile(
                    product: product,
                    onTap: () => _navigateToDetails(product),
                    onEdit: () => _navigateToForm(product.id),
                    onDelete: () => _controller.deleteProduct(product.id),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
