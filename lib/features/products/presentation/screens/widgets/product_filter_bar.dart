import 'package:flutter/material.dart';
import '../../../domain/models/product.dart';
import '../../controllers/product_controller.dart';

class ProductFilterBar extends StatelessWidget implements PreferredSizeWidget {
  final ProductController controller;

  const ProductFilterBar({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(110);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              controller.setSearch(val);
            },
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DropdownButton<String>(
                      hint: const Text('Category'),
                      value: controller.selectedCategoryId,
                      onChanged: (val) => controller.setCategory(val),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ...controller.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                      ],
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<StockStatus>(
                      hint: const Text('Stock Status'),
                      value: controller.selectedStockStatus,
                      onChanged: (val) => controller.setStockStatus(val),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Stock')),
                        ...StockStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        )),
                      ],
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<bool>(
                      hint: const Text('Status'),
                      value: controller.isActiveFilter,
                      onChanged: (val) => controller.setActiveFilter(val),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Status')),
                        DropdownMenuItem(value: true, child: Text('Active')),
                        DropdownMenuItem(value: false, child: Text('Inactive')),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
