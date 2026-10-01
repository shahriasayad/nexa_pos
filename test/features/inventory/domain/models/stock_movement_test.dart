import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/inventory/domain/models/stock_movement.dart';

void main() {
  group('StockMovement Model', () {
    test('creates properly', () {
      final movement = StockMovement(
        id: 'm1',
        productId: 'p1',
        quantityChange: 10,
        type: StockMovementType.purchase,
        previousStock: 5,
        newStock: 15,
        reason: 'Restock',
        timestamp: DateTime.now(),
      );
      
      expect(movement.id, 'm1');
      expect(movement.productId, 'p1');
      expect(movement.quantityChange, 10);
      expect(movement.type, StockMovementType.purchase);
      expect(movement.previousStock, 5);
      expect(movement.newStock, 15);
      expect(movement.reason, 'Restock');
    });
  });
}
