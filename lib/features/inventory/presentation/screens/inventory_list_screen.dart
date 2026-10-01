import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../categories/data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_inventory_repository.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_details_screen.dart';

import '../../../../core/layout/app_drawer.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  late InventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController(
      productRepo: MockProductRepository(),
      categoryRepo: MockCategoryRepository(),
      inventoryRepo: MockInventoryRepository(),
    );
    _controller.loadInventory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryDetailsScreen(
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
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search inventory...',
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
              return const LoadingView(message: 'Loading inventory...');
            case ViewState.error:
              return ErrorView(
                message: 'Failed to load',
                onRetry: _controller.loadInventory,
              );
            case ViewState.empty:
              return EmptyStateView(
                message: 'No inventory found',
                icon: Icons.inventory_2_outlined,
              );
            case ViewState.success:
              return ListView.builder(
                itemCount: _controller.products.length,
                itemBuilder: (context, index) {
                  final product = _controller.products[index];
                  final isLowStock = product.stockStatus != StockStatus.inStock;
                  final lastMove = _controller.lastMovements[product.id];
                  return ListTile(
                    onTap: () => _navigateToDetails(product),
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SKU: ${product.sku}'),
                        if (lastMove != null)
                          Text('Last: ${lastMove.type.name} (${lastMove.quantityChange > 0 ? '+' : ''}${lastMove.quantityChange})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
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
