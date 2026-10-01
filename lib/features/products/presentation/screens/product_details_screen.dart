import 'package:flutter/material.dart';
import '../../domain/models/product.dart';
import 'product_form_screen.dart';
import '../controllers/product_controller.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final ProductController controller;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductFormScreen(
                    controller: controller,
                    productId: product.id,
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Name', product.name),
                _buildRow('SKU', product.sku),
                _buildRow('Barcode', product.barcode ?? 'N/A'),
                _buildRow('Status', product.isActive ? 'Active' : 'Inactive'),
                _buildRow('Stock Status', product.stockStatus.name),
                _buildRow('Stock Qty', '${product.stockQuantity} ${product.unit}'),
                _buildRow('Min Stock', '${product.minimumStock} ${product.unit}'),
                _buildRow('Purchase Price', '\$${product.purchasePrice.toStringAsFixed(2)}'),
                _buildRow('Selling Price', '\$${product.sellingPrice.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
