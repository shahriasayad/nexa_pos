import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';
import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../domain/models/product.dart';
import '../controllers/product_controller.dart';
import '../../data/repositories/mock_product_repository.dart';
import '../../../categories/data/repositories/mock_category_repository.dart';
import 'product_form_screen.dart';
import 'product_details_screen.dart';

import '../../../../core/layout/app_shell.dart';
import 'widgets/product_filter_bar.dart';
import 'widgets/product_list_tile.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ProductController _controller;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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
    return AppShell(
      title: 'Products',
      actions: [
        CustomButton(
          label: 'Add Product',
          icon: Icons.add,
          onPressed: () => _navigateToForm(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        ),
      ],
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

          return Column(
            children: [
              ProductFilterBar(
                controller: _controller,
                searchController: _searchController,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  child: _buildContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
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
        return CustomCard(
          child: EmptyStateView(
            message: 'No products found',
            icon: Icons.inventory_2_outlined,
            actionLabel: 'Add Product',
            onAction: _navigateToForm,
          ),
        );
      case ViewState.success:
        return CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (!ResponsiveLayout.isMobile(context)) _buildTableHeader(),
              Expanded(
                child: ListView.builder(
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
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Product')),
          Expanded(flex: 2, child: _HeaderCell('Category')),
          Expanded(flex: 1, child: _HeaderCell('Price')),
          Expanded(flex: 1, child: _HeaderCell('Cost')),
          Expanded(flex: 1, child: _HeaderCell('Stock')),
          Expanded(flex: 1, child: _HeaderCell('Status')),
          const SizedBox(width: 80), // Actions space
        ],
      ),
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
