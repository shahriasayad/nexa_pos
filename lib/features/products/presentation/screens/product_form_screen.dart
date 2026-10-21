import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/products/presentation/controllers/product_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/custom_text_field.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductController controller;
  final String? productId;

  const ProductFormScreen({
    super.key,
    required this.controller,
    this.productId,
  });

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
      final matches = widget.controller.products.where(
        (p) => p.id == widget.productId,
      );
      if (matches.isNotEmpty) {
        _existingProduct = matches.first;
      }
    }

    _nameController = TextEditingController(text: _existingProduct?.name ?? '');
    _skuController = TextEditingController(text: _existingProduct?.sku ?? '');
    _barcodeController = TextEditingController(
      text: _existingProduct?.barcode ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: _existingProduct?.purchasePrice.toStringAsFixed(2) ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: _existingProduct?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    _stockController = TextEditingController(
      text: _existingProduct?.stockQuantity.toString() ?? '',
    );
    _minStockController = TextEditingController(
      text: _existingProduct?.minimumStock.toString() ?? '5',
    );

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
        id: _existingProduct?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        categoryId: _categoryId!,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stockQuantity: int.parse(_stockController.text),
        minimumStock: int.parse(_minStockController.text),
        isActive: _isActive,
        createdAt: _existingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.controller.saveProduct(product);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _existingProduct != null ? 'Edit Product' : 'Add New Product';

    return AppShell(
      title: title,
      showBottomNav: false,
      actions: [
        CustomButton(
          label: 'Cancel',
          variant: CustomButtonVariant.outline,
          height: 38,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        CustomButton(
          label: 'Save Product',
          icon: Icons.check,
          height: 38,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProductIdentityCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPricingCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInventoryCard(),
                  const SizedBox(height: AppSpacing.xl),
                  CustomButton(
                    label: _existingProduct != null
                        ? 'Update Product Details'
                        : 'Create Product',
                    icon: Icons.save_outlined,
                    isFullWidth: true,
                    height: 46,
                    fontSize: 15,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductIdentityCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Product Information'),
          const SizedBox(height: AppSpacing.sm),
          CustomTextField(
            label: 'Product Name *',
            hintText: 'e.g. Wireless Barcode Scanner',
            controller: _nameController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'SKU (Stock Keeping Unit) *',
                  hintText: 'e.g. ELEC-001',
                  controller: _skuController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'SKU is required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  label: 'Barcode (UPC / EAN)',
                  hintText: 'e.g. 890123456789',
                  controller: _barcodeController,
                  prefixIcon: const Icon(Icons.qr_code_scanner, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Category *',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            initialValue: _categoryId,
            items: widget.controller.categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (val) => setState(() => _categoryId = val),
            validator: (v) => v == null ? 'Please select a category' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    final cost = double.tryParse(_purchasePriceController.text) ?? 0.0;
    final price = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final margin = price > 0 ? ((price - cost) / price * 100) : 0.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Pricing & Margins'),
              if (price > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: margin >= 20 ? AppColors.primarySoft : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Margin: ${margin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: margin >= 20 ? AppColors.primaryStrong : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Purchase Cost (\$)*',
                  hintText: '0.00',
                  controller: _purchasePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money, size: 18),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Enter valid cost' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  label: 'Selling Price (\$)*',
                  hintText: '0.00',
                  controller: _sellingPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money, size: 18),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Enter valid price' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Inventory & Stock Controls'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Current Quantity *',
                  hintText: '0',
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Enter valid quantity' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  label: 'Minimum Stock Alert Threshold *',
                  hintText: '5',
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Enter valid threshold' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            title: const Text(
              'Active Product',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Active products are available in POS checkout catalog',
              style: TextStyle(fontSize: 12),
            ),
            value: _isActive,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
