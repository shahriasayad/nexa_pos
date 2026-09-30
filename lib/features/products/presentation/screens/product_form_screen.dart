import 'package:flutter/material.dart';
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
    _stockController = TextEditingController(text: _existingProduct?.stockQuantity.toString() ?? '0');
    _minStockController = TextEditingController(text: _existingProduct?.minimumStock.toString() ?? '0');
    
    _categoryId = _existingProduct?.categoryId ?? (widget.controller.categories.isNotEmpty ? widget.controller.categories.first.id : null);
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
    if (_formKey.currentState!.validate() && _categoryId != null) {
      final product = Product(
        id: _existingProduct?.id ?? '',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        categoryId: _categoryId!,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        minimumStock: int.tryParse(_minStockController.text) ?? 0,
        isActive: _isActive,
        createdAt: _existingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await widget.controller.saveProduct(product);
      if (success && mounted) {
        Navigator.pop(context);
      }
    } else if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingProduct == null ? 'New Product' : 'Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'SKU *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(labelText: 'Purchase Price *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(labelText: 'Selling Price *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock Qty *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(labelText: 'Min Stock *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
