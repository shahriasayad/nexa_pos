import '../models/stock_movement.dart';

abstract class InventoryRepository {
  Future<List<StockMovement>> getMovementsForProduct(String productId);
  Future<void> logMovement(StockMovement movement);
}
