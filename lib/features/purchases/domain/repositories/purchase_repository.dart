import '../models/purchase_order.dart';

abstract class PurchaseRepository {
  Future<List<PurchaseOrder>> getPurchases({
    String? supplierId,
    PurchaseStatus? status,
  });
  Future<PurchaseOrder?> getPurchaseById(String id);
  Future<void> savePurchase(PurchaseOrder purchase);
  Future<void> updatePurchase(PurchaseOrder purchase);
}
