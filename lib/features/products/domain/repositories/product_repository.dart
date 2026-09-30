import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? search, String? categoryId});
  Future<Product?> getProductById(String id);
  Future<Product> addProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<bool> checkSkuExists(String sku, {String? excludeId});
  Future<bool> checkBarcodeExists(String barcode, {String? excludeId});
  Future<int> getProductCountByCategory(String categoryId);
}
