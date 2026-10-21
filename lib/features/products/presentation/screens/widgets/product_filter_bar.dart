import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    Widget searchInput = SizedBox(
      height: 40,
      child: TextField(
        controller: searchController,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Search products by name or SKU...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: searchController?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    searchController?.clear();
                    controller.setSearch('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.normal),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.normal),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (val) => controller.setSearch(val),
      ),
    );

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final dropdowns = [
            _buildDropdown<String>(
              context,
              value: controller.selectedCategoryId,
              hint: 'All Categories',
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...controller.categories.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (val) => controller.setCategory(val),
              isDark: isDark,
            ),
            _buildDropdown<StockStatus>(
              context,
              value: controller.selectedStockStatus,
              hint: 'All Stock',
              items: [
                const DropdownMenuItem(value: null, child: Text('All Stock')),
                ...StockStatus.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (val) => controller.setStockStatus(val),
              isDark: isDark,
            ),
            _buildDropdown<bool>(
              context,
              value: controller.isActiveFilter,
              hint: 'All Status',
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: true, child: Text('Active')),
                DropdownMenuItem(value: false, child: Text('Inactive')),
              ],
              onChanged: (val) => controller.setActiveFilter(val),
              isDark: isDark,
            ),
          ];

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchInput,
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dropdowns.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: d,
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: searchInput),
              const SizedBox(width: AppSpacing.md),
              ...dropdowns.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: d,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context, {
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.normal),
        color: isDark ? AppColors.darkSurface : AppColors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12.5)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          borderRadius: BorderRadius.circular(AppRadius.normal),
        ),
      ),
    );
  }
}
