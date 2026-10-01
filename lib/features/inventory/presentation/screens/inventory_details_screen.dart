import 'package:flutter/material.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/models/stock_movement.dart';
import '../controllers/inventory_controller.dart';
import 'stock_adjustment_dialog.dart';

class InventoryDetailsScreen extends StatefulWidget {
  final Product product;
  final InventoryController controller;

  const InventoryDetailsScreen({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  late Future<List<StockMovement>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  void _loadMovements() {
    _movementsFuture = widget.controller.getProductMovements(widget.product.id);
  }

  void _showAdjustStockDialog() {
    showDialog(
      context: context,
      builder: (_) => StockAdjustmentDialog(
        product: widget.product,
        controller: widget.controller,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadMovements();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _showAdjustStockDialog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Movement History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<StockMovement>>(
              future: _movementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load history'));
                }
                final movements = snapshot.data ?? [];
                if (movements.isEmpty) {
                  return const Center(child: Text('No stock movements found.'));
                }
                return ListView.builder(
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final m = movements[index];
                    final isPositive = m.quantityChange > 0;
                    return ListTile(
                      leading: Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      title: Text('${m.type.name} - ${m.reason}'),
                      subtitle: Text('${m.timestamp.toString().split('.')[0]}\nNote: ${m.note ?? "N/A"}'),
                      isThreeLine: true,
                      trailing: Text(
                        '${isPositive ? '+' : ''}${m.quantityChange}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('SKU: ${widget.product.sku}'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Stock:'),
                Text('${widget.product.stockQuantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Min Stock:'),
                Text('${widget.product.minimumStock}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:'),
                Text(widget.product.stockStatus.name),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
