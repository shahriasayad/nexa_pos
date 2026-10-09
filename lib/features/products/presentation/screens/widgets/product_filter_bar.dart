import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_text_field.dart';

import '../../../domain/models/product.dart';
import '../../controllers/product_controller.dart';

class ProductFilterBar extends StatelessWidget {
  final ProductController controller;
  final TextEditingController? searchController;

  const ProductFilterBar({
    super.key,
    required this.controller,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: '',
                  hintText: 'Search products by name or SKU...',
                  prefixIcon: const Icon(Icons.search),
                  controller: searchController,
                  onChanged: (val) {
                    controller.setSearch(val);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDropdown<String>(
                        context,
                        value: controller.selectedCategoryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...controller.categories.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => controller.setCategory(val),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildDropdown<StockStatus>(
                        context,
                        value: controller.selectedStockStatus,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Stock'),
                          ),
                          ...StockStatus.values.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: (val) => controller.setStockStatus(val),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildDropdown<bool>(
                        context,
                        value: controller.isActiveFilter,
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (val) => controller.setActiveFilter(val),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context, {
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down),
          style: Theme.of(context).textTheme.bodyMedium,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
