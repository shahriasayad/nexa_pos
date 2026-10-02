import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../features/pos/domain/models/sale_transaction.dart';
import '../../../../features/products/data/repositories/mock_product_repository.dart';
import '../../../../features/inventory/data/repositories/mock_inventory_repository.dart';
import '../../../../features/pos/data/repositories/mock_sales_repository.dart';
import '../../domain/models/return_transaction.dart';
import '../controllers/return_controller.dart';

class ReturnDialog extends StatefulWidget {
  final SaleTransaction sale;
  final MockSalesRepository salesRepo;

  const ReturnDialog({super.key, required this.sale, required this.salesRepo});

  @override
  State<ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<ReturnDialog> {
  late ReturnController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReturnController(
      salesRepo: widget.salesRepo,
      productRepo: MockProductRepository(),
      inventoryRepo: MockInventoryRepository(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final refundAmount = _controller.calculateRefundAmount(widget.sale);
        
        return AlertDialog(
          title: const Text('Return Items'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.errorMessage != null)
                    Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)),
                  
                  ...widget.sale.items.map((item) {
                    final maxReturnable = item.quantity - item.returnedQuantity;
                    if (maxReturnable <= 0) return const SizedBox.shrink();
                    
                    final selectedQty = _controller.returnQuantities[item.productId] ?? 0;
                    return ListTile(
                      title: Text(item.productName),
                      subtitle: Text('Max returnable: $maxReturnable @ \$${item.unitPrice.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _controller.setReturnQuantity(item.productId, selectedQty - 1, maxReturnable),
                          ),
                          Text('$selectedQty'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _controller.setReturnQuantity(item.productId, selectedQty + 1, maxReturnable),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const Divider(),
                  DropdownButtonFormField<ReturnReason>(
                    value: _controller.selectedReason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: ReturnReason.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase()),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) _controller.selectedReason = v;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PaymentMethod>(
                    value: _controller.refundMethod,
                    decoration: const InputDecoration(labelText: 'Refund Method'),
                    items: PaymentMethod.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase()),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) _controller.refundMethod = v;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Total Refund: \$${refundAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  
                  if (_controller.state == ViewState.loading)
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _controller.state == ViewState.loading ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _controller.state == ViewState.loading ? null : () async {
                final success = await _controller.submitReturn(widget.sale);
                if (success && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirm Return'),
            ),
          ],
        );
      }
    );
  }
}
