import 'package:nexa_pos/core/auth/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/returns/presentation/controllers/return_controller.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';

void main() {
  group('ReturnController', () {
    late MockSalesRepository salesRepo;
    late MockProductRepository productRepo;
    late MockInventoryRepository inventoryRepo;
    late ReturnController controller;
    late SaleTransaction testSale;

    setUp(() async {
      AuthProvider.instance.testLoginAdmin();
      salesRepo = MockSalesRepository();
      productRepo = MockProductRepository();
      inventoryRepo = MockInventoryRepository();
      controller = ReturnController(
        salesRepo: salesRepo,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
      );

      // Create test product
      await productRepo.addProduct(Product(
        id: 'p1', name: 'Product 1', sku: 'sku1', barcode: '123',
        sellingPrice: 100, purchasePrice: 50,
        stockQuantity: 10, minimumStock: 5, categoryId: 'cat1',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      testSale = SaleTransaction(
        id: 'txn1', timestamp: DateTime.now(),
        items: [SaleItem(productId: 'p1', productName: 'Product 1', productSku: 'sku1', unitPrice: 100, quantity: 5, lineTotal: 500)],
        subtotal: 500, discount: 0, tax: 0, total: 500,
        paymentMethod: PaymentMethod.cash, amountReceived: 500, change: 0, status: SaleStatus.completed,
      );
      await salesRepo.createSale(testSale);
    });

    test('setReturnQuantity restricts exceeding max', () {
      controller.setReturnQuantity('p1', 6, 5);
      expect(controller.errorMessage, 'Cannot return more than purchased.');
      expect(controller.returnQuantities['p1'] ?? 0, 0);

      controller.setReturnQuantity('p1', 3, 5);
      expect(controller.errorMessage, isNull);
      expect(controller.returnQuantities['p1'], 3);
    });

    test('calculateRefundAmount uses original historical price', () {
      controller.setReturnQuantity('p1', 2, 5);
      expect(controller.calculateRefundAmount(testSale), 200.0);
    });

    test('submitReturn updates inventory and sale status correctly for partial return', () async {
      controller.setReturnQuantity('p1', 2, 5);
      final success = await controller.submitReturn(testSale);
      expect(success, true);
      
      final product = await productRepo.getProductById('p1');
      expect(product!.stockQuantity, 12); // 10 original + 2 returned
      
      final updatedSale = await salesRepo.getSale('txn1');
      expect(updatedSale!.returns.length, 1);
      expect(updatedSale.items.first.returnedQuantity, 2);
      expect(updatedSale.status, SaleStatus.completed); // Still partial
    });

    test('submitReturn updates status to refunded for full return', () async {
      controller.setReturnQuantity('p1', 5, 5);
      await controller.submitReturn(testSale);
      
      final updatedSale = await salesRepo.getSale('txn1');
      expect(updatedSale!.items.first.returnedQuantity, 5);
      expect(updatedSale.status, SaleStatus.refunded); 
    });
  });
}
