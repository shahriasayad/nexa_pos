import '../models/sale_transaction.dart';

abstract class SalesRepository {
  Future<void> createSale(SaleTransaction sale);
  Future<List<SaleTransaction>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
  });
  Future<SaleTransaction?> getSale(String id);
}
