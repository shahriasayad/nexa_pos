import 'package:nexa_pos/core/auth/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/customers/data/repositories/mock_customer_repository.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/pos_controller.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';

void main() {
  group('PosController', () {
    late PosController controller;
    late MockProductRepository productRepo;
    late MockInventoryRepository inventoryRepo;
    late MockSalesRepository salesRepo;
    late MockCustomerRepository customerRepo;

    setUp(() {
      AuthProvider.instance.testLoginAdmin();
      productRepo = MockProductRepository();
      inventoryRepo = MockInventoryRepository();
      salesRepo = MockSalesRepository();
      customerRepo = MockCustomerRepository();
      controller = PosController(
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        salesRepo: salesRepo,
        customerRepo: customerRepo,
      );
    });

    test('add to cart respects stock', () async {
      await controller.searchProducts(null);
      final product = controller.searchResults.first; // Stock is 2
      
      controller.addToCart(product);
      expect(controller.cart.length, 1);
      
      controller.addToCart(product); // Qty becomes 2
      expect(controller.cart.first.quantity, 2);
      
      controller.addToCart(product); // Trying to add 3rd
      expect(controller.errorMessage, contains('Cannot exceed available stock'));
      expect(controller.cart.first.quantity, 2);
    });

    test('update quantity updates cart', () async {
      await controller.searchProducts(null);
      final product = controller.searchResults.first;
      
      controller.addToCart(product);
      controller.updateQuantity(product, 2);
      expect(controller.cart.first.quantity, 2);
    });

    test('checkout succeeds, deducts inventory, creates sale', () async {
      await controller.searchProducts(null);
      final product = controller.searchResults.first; // Stock is 2
      
      controller.addToCart(product);
      controller.updateQuantity(product, 2);
      
      final subtotal = controller.subtotal;
      
      final result = await controller.checkout(PaymentMethod.cash, subtotal);
      
      expect(result, true);
      expect(controller.cart.isEmpty, true);
      expect(controller.lastCompletedSale, isNotNull);
      
      // Verify inventory deducted
      final updatedProduct = await productRepo.getProductById(product.id);
      expect(updatedProduct!.stockQuantity, 0); // 2 - 2 = 0
      
      // Verify sale recorded
      final sales = await salesRepo.getSales();
      expect(sales.length, 1);
      expect(sales.first.items.first.productId, product.id);
    });

    test('checkout fails if insufficient payment', () async {
      await controller.searchProducts(null);
      final product = controller.searchResults.first;
      
      controller.addToCart(product);
      
      final result = await controller.checkout(PaymentMethod.cash, 0); // Need $25
      
      expect(result, false);
      expect(controller.errorMessage, 'Insufficient payment amount.');
    });
  });
}
