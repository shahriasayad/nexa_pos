import 'package:flutter/material.dart';
import '../../controllers/pos_controller.dart';

class ProductListPanel extends StatelessWidget {
  final PosController controller;
  final TextEditingController searchController;

  const ProductListPanel({
    super.key,
    required this.controller,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search products by name/SKU/barcode...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => controller.searchProducts(val),
          ),
        ),
        Expanded(
          child: controller.searchResults.isEmpty
              ? const Center(child: Text('No products found or available in stock.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final product = controller.searchResults[index];
                    return Card(
                      child: InkWell(
                        onTap: () => controller.addToCart(product),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(product.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('\$${product.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 16)),
                              const Spacer(),
                              Text('Stock: ${product.stockQuantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
