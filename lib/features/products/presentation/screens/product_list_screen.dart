import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/categories/data/repositories/mock_category_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/products/presentation/controllers/product_controller.dart';
import 'package:nexa_pos/features/products/presentation/screens/product_details_screen.dart';
import 'package:nexa_pos/features/products/presentation/screens/product_form_screen.dart';
import 'package:nexa_pos/features/products/presentation/screens/widgets/product_filter_bar.dart';
import 'package:nexa_pos/features/products/presentation/screens/widgets/product_list_tile.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

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
        builder: (_) =>
            ProductFormScreen(controller: _controller, productId: productId),
      ),
    );
  }

  void _navigateToDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailsScreen(controller: _controller, product: product),
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
          height: 38,
          onPressed: () => _navigateToForm(),
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

          return Column(
            children: [
              ProductFilterBar(
                controller: _controller,
                searchController: _searchController,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
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
          message: _controller.errorMessage ?? 'Failed to load products',
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          Expanded(flex: 2, child: _HeaderCell('CATEGORY')),
          Expanded(flex: 1, child: _HeaderCell('PRICE')),
          Expanded(flex: 1, child: _HeaderCell('COST')),
          Expanded(flex: 1, child: _HeaderCell('STOCK')),
          Expanded(flex: 1, child: _HeaderCell('STATUS')),
          SizedBox(width: 80, child: _HeaderCell('ACTIONS', alignment: TextAlign.right)),
        ],
      ),
    );
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
