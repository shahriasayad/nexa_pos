import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/categories/domain/models/category.dart';
import 'package:nexa_pos/features/categories/presentation/controllers/category_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late CategoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CategoryController(
      categoryRepo: AppRepositories.instance.categoryRepo,
      productRepo: AppRepositories.instance.productRepo,
    );
    _controller.loadCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFormDialog([Category? category]) {
    showDialog(
      context: context,
      builder: (context) =>
          _CategoryFormDialog(controller: _controller, category: category),
    );
  }

  void _confirmDeleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Categories',
      actions: [
        CustomButton(
          label: 'Add Category',
          icon: Icons.add,
          height: 38,
          onPressed: () => _showFormDialog(),
        ),
      ],
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _controller.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_controller.errorMessage!),
                    backgroundColor: AppColors.danger,
                  ),
                );
                _controller.clearError();
              }
            });
          }

          switch (_controller.state) {
            case ViewState.initial:
            case ViewState.loading:
              return const LoadingView(message: 'Loading categories...');
            case ViewState.error:
              return ErrorView(
                message: _controller.errorMessage ?? 'Failed to load categories',
                onRetry: _controller.loadCategories,
              );
            case ViewState.empty:
              return EmptyStateView(
                message: 'No categories found',
                icon: Icons.category_outlined,
                actionLabel: 'Add Category',
                onAction: _showFormDialog,
              );
            case ViewState.success:
              return _buildCategoryGrid(context);
          }
        },
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = _controller.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATALOG GROUPS (${categories.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 140,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return CustomCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceMuted
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            size: 20,
                            color: isDark ? AppColors.darkSuccess : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          label: cat.isActive ? 'Active' : 'Inactive',
                          type: cat.isActive ? BadgeType.success : BadgeType.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        cat.description.isNotEmpty
                            ? cat.description
                            : 'No description provided',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showFormDialog(cat),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () => _confirmDeleteCategory(cat),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: AppColors.danger,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 12, color: AppColors.danger),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
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

class _CategoryFormDialog extends StatefulWidget {
  final CategoryController controller;
  final Category? category;

  const _CategoryFormDialog({required this.controller, this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descController = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final cat = Category(
        id: widget.category?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        isActive: _isActive,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final success = await widget.controller.saveCategory(cat);
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category == null ? 'New Category' : 'Edit Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g. Beverages',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Cold drinks, juices, coffee',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: const Text(
                    'Active Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Active categories appear in POS filter chips',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isActive,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Cancel',
                        variant: CustomButtonVariant.outline,
                        height: 42,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        label: 'Save Category',
                        variant: CustomButtonVariant.primary,
                        height: 42,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
