import 'package:flutter/material.dart';

import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../domain/models/category.dart';
import '../controllers/category_controller.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../../products/data/repositories/mock_product_repository.dart';

import '../../../../core/layout/app_shell.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

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
      categoryRepo: MockCategoryRepository(),
      productRepo: MockProductRepository(),
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Categories',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
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
                  SnackBar(content: Text(_controller.errorMessage!)),
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
                message: 'Failed to load',
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
              return ListView.builder(
                itemCount: _controller.categories.length,
                itemBuilder: (context, index) {
                  final cat = _controller.categories[index];
                  return ListTile(
                    title: Text(cat.name),
                    subtitle: Text(cat.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showFormDialog(cat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.danger,
                          ),
                          onPressed: () => _controller.deleteCategory(cat.id),
                        ),
                      ],
                    ),
                  );
                },
              );
          }
        },
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
    return AlertDialog(
      title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
