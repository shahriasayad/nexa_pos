import 'package:flutter/material.dart';
import '../../domain/models/product_summary.dart';

class TopProductsList extends StatelessWidget {
  final String title;
  final List<ProductSummary> products;
  final bool isLowStock;

  const TopProductsList({
    super.key,
    required this.title,
    required this.products,
    this.isLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No products to display')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    isLowStock
                        ? 'Stock: ${product.stockQuantity}'
                        : 'Sold: ${product.soldQuantity}',
                    style: TextStyle(
                      color: isLowStock ? Colors.orange : null,
                      fontWeight: isLowStock ? FontWeight.bold : null,
                    ),
                  ),
                  trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                );
              },
            ),
        ],
      ),
    );
  }
}
