import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/pos/domain/models/cart_item.dart';

void main() {
  group('CartItem Model', () {
    test('calculates line total correctly', () {
      final product = Product(
        id: '1', name: 'Test', sku: 'SKU1', categoryId: 'C1',
        purchasePrice: 10, sellingPrice: 20, stockQuantity: 10, minimumStock: 5,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final item = CartItem(product: product, quantity: 3);
      expect(item.lineTotal, 60.0);
    });
  });
}
