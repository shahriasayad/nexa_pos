import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../../returns/domain/models/return_transaction.dart';

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
      if (paymentMethod != null && s.paymentMethod != paymentMethod) {
        return false;
      }
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

  @override
  Future<void> returnItems(String saleId, ReturnTransaction returnTx) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final saleIndex = _sales.indexWhere((s) => s.id == saleId);
    if (saleIndex == -1) throw Exception('Sale not found');

    final sale = _sales[saleIndex];
    final updatedItems = sale.items.map((item) {
      final returned = returnTx.items
          .where((r) => r.productId == item.productId)
          .firstOrNull;
      if (returned != null) {
        return item.copyWith(
          returnedQuantity: item.returnedQuantity + returned.quantity,
        );
      }
      return item;
    }).toList();

    bool allReturned = true;
    for (var item in updatedItems) {
      if (item.returnedQuantity < item.quantity) {
        allReturned = false;
        break;
      }
    }

    final newStatus = allReturned ? SaleStatus.refunded : SaleStatus.completed;

    _sales[saleIndex] = sale.copyWith(
      status: newStatus,
      items: updatedItems,
      returns: [...sale.returns, returnTx],
    );
  }
}
