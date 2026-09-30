import '../../../../core/error/failures.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';

class MockProductRepository implements ProductRepository {
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Wireless Mouse',
      sku: 'SKU-001',
      barcode: '1234567890',
      categoryId: '1',
      purchasePrice: 15.0,
      sellingPrice: 25.0,
      stockQuantity: 2,
      minimumStock: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: '2',
      name: 'Mechanical Keyboard',
      sku: 'SKU-002',
      categoryId: '1',
      purchasePrice: 80.0,
      sellingPrice: 120.0,
      stockQuantity: 10,
      minimumStock: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Product>> getProducts({String? search, String? categoryId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _products.where((p) {
      bool matchesSearch = search == null || 
          p.name.toLowerCase().contains(search.toLowerCase()) ||
          p.sku.toLowerCase().contains(search.toLowerCase());
      bool matchesCategory = categoryId == null || p.categoryId == categoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (await checkSkuExists(product.sku)) {
      throw const BusinessFailure('SKU already exists.');
    }
    if (product.barcode != null && product.barcode!.isNotEmpty && await checkBarcodeExists(product.barcode!)) {
      throw const BusinessFailure('Barcode already exists.');
    }
    _products.add(product);
    return product;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (await checkSkuExists(product.sku, excludeId: product.id)) {
      throw const BusinessFailure('SKU already exists.');
    }
    if (product.barcode != null && product.barcode!.isNotEmpty && await checkBarcodeExists(product.barcode!, excludeId: product.id)) {
      throw const BusinessFailure('Barcode already exists.');
    }
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) throw const BusinessFailure('Product not found.');
    _products[index] = product;
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<bool> checkSkuExists(String sku, {String? excludeId}) async {
    return _products.any((p) => p.sku.toLowerCase() == sku.toLowerCase() && p.id != excludeId);
  }

  @override
  Future<bool> checkBarcodeExists(String barcode, {String? excludeId}) async {
    return _products.any((p) => p.barcode == barcode && p.id != excludeId);
  }

  @override
  Future<int> getProductCountByCategory(String categoryId) async {
    return _products.where((p) => p.categoryId == categoryId).length;
  }
}
