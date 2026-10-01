import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/sales_repository.dart';

class MockSalesRepository implements SalesRepository {
  final List<SaleTransaction> _sales = [];

  @override
  Future<void> createSale(SaleTransaction sale) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sales.add(sale);
  }

  @override
  Future<List<SaleTransaction>> getSales() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List<SaleTransaction>.from(_sales);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  @override
  Future<SaleTransaction?> getSale(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}