import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/custom_text_field.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';
import '../../../../core/layout/app_shell.dart';
import '../../domain/models/product.dart';
import '../controllers/product_controller.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductController controller;
  final String? productId;

  const ProductFormScreen({super.key, required this.controller, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  
  String? _categoryId;
  bool _isActive = true;
  Product? _existingProduct;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _existingProduct = widget.controller.products.firstWhere((p) => p.id == widget.productId);
    }

    _nameController = TextEditingController(text: _existingProduct?.name ?? '');
    _skuController = TextEditingController(text: _existingProduct?.sku ?? '');
    _barcodeController = TextEditingController(text: _existingProduct?.barcode ?? '');
    _purchasePriceController = TextEditingController(text: _existingProduct?.purchasePrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: _existingProduct?.sellingPrice.toString() ?? '');
    _stockController = TextEditingController(text: _existingProduct?.stockQuantity.toString() ?? '');
    _minStockController = TextEditingController(text: _existingProduct?.minimumStock.toString() ?? '');
    
    _categoryId = _existingProduct?.categoryId;
    _isActive = _existingProduct?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: _existingProduct?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        categoryId: _categoryId!,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stockQuantity: int.parse(_stockController.text),
        minimumStock: int.parse(_minStockController.text),
        isActive: _isActive, createdAt: _existingProduct?.createdAt ?? DateTime.now(), updatedAt: DateTime.now(),
      );

      if (_existingProduct != null) {
        await widget.controller.saveProduct(product);
      } else {
        await widget.controller.saveProduct(product);
      }
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _existingProduct != null ? 'Edit Product' : 'Add Product';
    
    return AppShell(
      title: title,
      actions: [
        CustomButton(
          label: 'Save Product',
          onPressed: _submit,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        ),
      ],
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductInformation(),
                const SizedBox(height: AppSpacing.xl),
                _buildPricing(),
                const SizedBox(height: AppSpacing.xl),
                _buildInventory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInformation() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Product Information'),
          CustomTextField(
            label: 'Product Name *',
            controller: _nameController,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'SKU *',
                  controller: _skuController,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  label: 'Barcode',
                  controller: _barcodeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Category *'),
            value: _categoryId,
            items: widget.controller.categories.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name),
            )).toList(),
            onChanged: (val) => setState(() => _categoryId = val),
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricing() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Pricing'),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Purchase Price *',
                  controller: _purchasePriceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.attach_money),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  label: 'Selling Price *',
                  controller: _sellingPriceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.attach_money),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Inventory & Status'),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Initial Stock *',
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  label: 'Minimum Stock *',
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            title: const Text('Product is Active'),
            subtitle: const Text('Inactive products are hidden from POS checkout'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
