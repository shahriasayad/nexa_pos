import 'package:flutter/material.dart';
import '../../../domain/models/product.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockStatus != StockStatus.inStock;
    return ListTile(
      onTap: onTap,
      title: Text(product.name),
      subtitle: Text('SKU: ${product.sku} | Price: \$${product.sellingPrice.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLowStock)
            Icon(
              product.stockStatus == StockStatus.outOfStock ? Icons.error : Icons.warning,
              color: product.stockStatus == StockStatus.outOfStock ? Colors.red : Colors.orange,
            ),
          const SizedBox(width: 8),
          Text(
            'Stock: ${product.stockQuantity}',
            style: TextStyle(
              color: product.stockStatus == StockStatus.outOfStock ? Colors.red : null,
              fontWeight: isLowStock ? FontWeight.bold : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
