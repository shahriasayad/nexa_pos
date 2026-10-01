import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/categories/data/repositories/mock_category_repository.dart';
import 'package:nexa_pos/features/products/presentation/controllers/product_controller.dart';

void main() {
  group('ProductController', () {
    late ProductController controller;

    setUp(() {
      controller = ProductController(
        productRepo: MockProductRepository(),
        categoryRepo: MockCategoryRepository(),
      );
    });

    test('initial state is ViewState.initial', () {
      expect(controller.state, ViewState.initial);
    });

    test('loadProducts fetches data and sets success', () async {
      await controller.loadProducts();
      expect(controller.state, ViewState.success);
      expect(controller.products.isNotEmpty, true);
    });

    test('setSearch filters products', () async {
      await controller.loadProducts();
      controller.setSearch('Mouse');
      await Future.delayed(const Duration(milliseconds: 400));
      expect(controller.products.length, 1);
      expect(controller.products.first.name, 'Wireless Mouse');
    });

    test('saveProduct adds new product', () async {
      await controller.loadProducts();
      final initialCount = controller.products.length;
      final p = Product(
        id: '', name: 'New Item', sku: 'NEW-01', categoryId: '1',
        purchasePrice: 5, sellingPrice: 10, stockQuantity: 100,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final success = await controller.saveProduct(p);
      expect(success, true);
      expect(controller.products.length, initialCount + 1);
    });
  });
}
