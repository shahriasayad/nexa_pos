import '../models/sale_transaction.dart';

abstract class SalesRepository {
  Future<void> createSale(SaleTransaction sale);
  Future<List<SaleTransaction>> getSales();
  Future<SaleTransaction?> getSale(String id);
}
