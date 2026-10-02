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
  Future<List<SaleTransaction>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var filtered = _sales.where((s) {
      if (startDate != null && s.timestamp.isBefore(startDate)) return false;
      if (endDate != null && s.timestamp.isAfter(endDate)) return false;
      if (paymentMethod != null && s.paymentMethod != paymentMethod) return false;
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
    
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
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