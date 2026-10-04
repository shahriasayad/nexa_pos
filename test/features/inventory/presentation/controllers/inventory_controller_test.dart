import 'package:nexa_pos/core/auth/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/categories/data/repositories/mock_category_repository.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:nexa_pos/features/inventory/domain/models/stock_movement.dart';

void main() {
  group('InventoryController', () {
    late InventoryController controller;
    late MockProductRepository productRepo;
    late MockInventoryRepository inventoryRepo;

    setUp(() {
      AuthProvider.instance.testLoginAdmin();
      productRepo = MockProductRepository();
      inventoryRepo = MockInventoryRepository();
      controller = InventoryController(
        productRepo: productRepo,
        categoryRepo: MockCategoryRepository(),
        inventoryRepo: inventoryRepo,
      );
    });

    test('adjustStock decreases stock correctly', () async {
      await controller.loadInventory();
      final product = controller.products.first; // Stock is 2
      final previousStock = product.stockQuantity;
      
      final success = await controller.adjustStock(
        product: product,
        quantityChange: -1,
        type: StockMovementType.sale,
        reason: 'Test sale',
      );
      
      expect(success, true);
      
      final updatedProduct = await productRepo.getProductById(product.id);
      expect(updatedProduct!.stockQuantity, previousStock - 1);
      
      final movements = await inventoryRepo.getMovementsForProduct(product.id);
      expect(movements.length, 1);
      expect(movements.first.quantityChange, -1);
      expect(movements.first.newStock, previousStock - 1);
    });

    test('adjustStock prevents negative stock', () async {
      await controller.loadInventory();
      final product = controller.products.first; // Stock is 2
      
      final success = await controller.adjustStock(
        product: product,
        quantityChange: -5, // Trying to drop below 0
        type: StockMovementType.manualAdjustment,
        reason: 'Test adjust',
      );
      
      expect(success, false);
      expect(controller.errorMessage, 'Stock cannot be negative.');
      
      final movements = await inventoryRepo.getMovementsForProduct(product.id);
      expect(movements.isEmpty, true);
    });
    
    test('adjustStock rejects zero change', () async {
      await controller.loadInventory();
      final product = controller.products.first; 
      
      final success = await controller.adjustStock(
        product: product,
        quantityChange: 0, 
        type: StockMovementType.manualAdjustment,
        reason: 'Zero',
      );
      
      expect(success, false);
      expect(controller.errorMessage, 'Quantity change cannot be zero.');
    });
  });
}
