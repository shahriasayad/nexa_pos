import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/features/purchases/domain/models/purchase_order.dart';
import 'package:nexa_pos/features/purchases/data/repositories/mock_purchase_repository.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/purchases/presentation/controllers/purchase_controller.dart';

void main() {
  group('PurchaseController', () {
    late MockPurchaseRepository purchaseRepo;
    late MockInventoryRepository inventoryRepo;
    late MockProductRepository productRepo;
    late PurchaseController controller;

    setUp(() {
      purchaseRepo = MockPurchaseRepository();
      inventoryRepo = MockInventoryRepository();
      productRepo = MockProductRepository();
      controller = PurchaseController(
        purchaseRepo: purchaseRepo,
        inventoryRepo: inventoryRepo,
        productRepo: productRepo,
      );
    });

    test('initial state is ViewState.initial', () {
      expect(controller.state, ViewState.initial);
    });

    test('savePurchase adds new purchase', () async {
      final po = PurchaseOrder(
        id: 'new-po',
        supplierId: 'sup-1',
        supplierName: 'Sup 1',
        status: PurchaseStatus.draft,
        items: [],
        totalAmount: 0,
        orderDate: DateTime.now(),
      );

      final success = await controller.savePurchase(po);
      expect(success, true);
      
      final saved = await purchaseRepo.getPurchaseById('new-po');
      expect(saved, isNotNull);
      expect(saved!.id, 'new-po');
    });

    test('receivePurchase updates inventory and status', () async {
      final po = PurchaseOrder(
        id: 'new-po',
        supplierId: 'sup-1',
        supplierName: 'Sup 1',
        status: PurchaseStatus.ordered,
        items: [
          PurchaseItem(productId: '1', productName: 'Wireless Mouse', quantity: 10, unitCost: 15.0)
        ],
        totalAmount: 150,
        orderDate: DateTime.now(),
      );
      
      await controller.savePurchase(po);
      
      // Assume receiving 5
      final receivedItems = [
        PurchaseItem(productId: '1', productName: 'Wireless Mouse', quantity: 10, unitCost: 15.0, receivedQuantity: 5)
      ];
      
      final success = await controller.receivePurchase(po, receivedItems);
      expect(success, true);
      
      final updatedPo = await purchaseRepo.getPurchaseById('new-po');
      expect(updatedPo!.status, PurchaseStatus.received);
      
      final movements = await inventoryRepo.getMovementsForProduct('1');
      expect(movements.isNotEmpty, true);
      expect(movements.first.quantityChange, 5);
      
      final product = await productRepo.getProductById('1');
      // MockProductRepository starts product '1' with 2 stock
      expect(product!.stockQuantity, 7);
    });
  });
}
