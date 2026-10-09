import 'package:flutter/material.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/purchase_order.dart';
import '../../data/repositories/mock_purchase_repository.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../inventory/data/repositories/mock_inventory_repository.dart';
import '../controllers/purchase_controller.dart';
import 'purchase_form_screen.dart';
import 'receive_purchase_screen.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  late PurchaseController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PurchaseController(
      purchaseRepo: MockPurchaseRepository(),
      inventoryRepo: MockInventoryRepository(),
      productRepo: MockProductRepository(),
    );
    _controller.loadPurchases();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPurchaseForm([PurchaseOrder? purchase]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PurchaseFormScreen(purchase: purchase)),
    );
    if (result == true) {
      _controller.loadPurchases();
    }
  }

  void _receivePurchase(PurchaseOrder purchase) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceivePurchaseScreen(purchase: purchase),
      ),
    );
    if (result == true) {
      _controller.loadPurchases();
    }
  }

  Color _getStatusColor(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.draft:
        return AppColors.grey;
      case PurchaseStatus.ordered:
        return AppColors.info;
      case PurchaseStatus.received:
        return AppColors.success;
      case PurchaseStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Purchases',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _openPurchaseForm(),
        ),
      ],
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.state == ViewState.error) {
            return Center(
              child: Text(
                _controller.errorMessage ?? 'Error loading purchases',
              ),
            );
          }
          if (_controller.state == ViewState.empty) {
            return const Center(child: Text('No purchases found.'));
          }

          return ListView.builder(
            itemCount: _controller.purchases.length,
            itemBuilder: (context, index) {
              final purchase = _controller.purchases[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('PO-${purchase.id} - ${purchase.supplierName}'),
                  subtitle: Text(
                    '${purchase.orderDate.toString().split(' ')[0]} - ${purchase.items.length} items',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(purchase.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(purchase.status),
                          ),
                        ),
                        child: Text(
                          purchase.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(purchase.status),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (purchase.status == PurchaseStatus.draft)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openPurchaseForm(purchase),
                        ),
                      if (purchase.status == PurchaseStatus.ordered)
                        IconButton(
                          icon: const Icon(Icons.inventory),
                          onPressed: () => _receivePurchase(purchase),
                          tooltip: 'Receive Stock',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
