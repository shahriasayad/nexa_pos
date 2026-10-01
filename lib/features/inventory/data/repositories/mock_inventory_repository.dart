import '../../domain/models/stock_movement.dart';
import '../../domain/repositories/inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  final List<StockMovement> _movements = [];

  @override
  Future<List<StockMovement>> getMovementsForProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final result = _movements.where((m) => m.productId == productId).toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  @override
  Future<void> logMovement(StockMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _movements.add(movement);
  }
}
