import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';

void main() {
  group('Product Model', () {
    test('stockStatus returns outOfStock when quantity is 0', () {
      final product = Product(
        id: '1', name: 'Test', sku: 'SKU1', categoryId: 'C1',
        purchasePrice: 10, sellingPrice: 20, stockQuantity: 0, minimumStock: 5,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(product.stockStatus, StockStatus.outOfStock);
    });

    test('stockStatus returns lowStock when quantity <= minimumStock', () {
      final product = Product(
        id: '1', name: 'Test', sku: 'SKU1', categoryId: 'C1',
        purchasePrice: 10, sellingPrice: 20, stockQuantity: 5, minimumStock: 5,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(product.stockStatus, StockStatus.lowStock);
    });

    test('stockStatus returns inStock when quantity > minimumStock', () {
      final product = Product(
        id: '1', name: 'Test', sku: 'SKU1', categoryId: 'C1',
        purchasePrice: 10, sellingPrice: 20, stockQuantity: 10, minimumStock: 5,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(product.stockStatus, StockStatus.inStock);
    });
  });
}
