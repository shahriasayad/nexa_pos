import 'package:flutter/material.dart';

import '../../domain/models/purchase_order.dart';
import '../../data/repositories/mock_purchase_repository.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../inventory/data/repositories/mock_inventory_repository.dart';
import '../controllers/purchase_controller.dart';

class ReceivePurchaseScreen extends StatefulWidget {
  final PurchaseOrder purchase;

  const ReceivePurchaseScreen({super.key, required this.purchase});

  @override
  State<ReceivePurchaseScreen> createState() => _ReceivePurchaseScreenState();
}

class _ReceivePurchaseScreenState extends State<ReceivePurchaseScreen> {
  late PurchaseController _controller;
  late List<PurchaseItem> _items;

  @override
  void initState() {
    super.initState();
    _controller = PurchaseController(
      purchaseRepo: MockPurchaseRepository(),
      inventoryRepo: MockInventoryRepository(),
      productRepo: MockProductRepository(),
    );
    // Initialize received quantity to the ordered quantity by default (assuming full receipt)
    _items = widget.purchase.items
        .map((item) => item.copyWith(receivedQuantity: item.quantity))
        .toList();
  }

  void _updateReceivedQuantity(int index, String value) {
    final qty = int.tryParse(value) ?? 0;
    setState(() {
      _items[index] = _items[index].copyWith(receivedQuantity: qty);
    });
  }

  void _receive() async {
    final success = await _controller.receivePurchase(widget.purchase, _items);
    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Failed to receive purchase',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Receive PO-${widget.purchase.id}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Supplier: ${widget.purchase.supplierName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Text('Ordered: ${item.quantity}'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: item.receivedQuantity.toString(),
                      decoration: const InputDecoration(labelText: 'Received'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _updateReceivedQuantity(index, val),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _receive,
                child: const Text('Confirm Receipt & Update Inventory'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
