import '../../domain/models/purchase_order.dart';
import '../../domain/repositories/purchase_repository.dart';

class MockPurchaseRepository implements PurchaseRepository {
  final List<PurchaseOrder> _purchases = [];

  @override
  Future<List<PurchaseOrder>> getPurchases({
    String? supplierId,
    PurchaseStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = _purchases.toList();
    if (supplierId != null) {
      results = results.where((p) => p.supplierId == supplierId).toList();
    }
    if (status != null) {
      results = results.where((p) => p.status == status).toList();
    }
    results.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return results;
  }

  @override
  Future<PurchaseOrder?> getPurchaseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _purchases.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> savePurchase(PurchaseOrder purchase) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _purchases.add(purchase);
  }

  @override
  Future<void> updatePurchase(PurchaseOrder purchase) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _purchases.indexWhere((p) => p.id == purchase.id);
    if (index >= 0) {
      _purchases[index] = purchase;
    } else {
      throw Exception('Purchase not found');
    }
  }
}
