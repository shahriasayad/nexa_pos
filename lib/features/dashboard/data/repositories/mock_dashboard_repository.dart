import '../../domain/models/dashboard_metrics.dart';
import '../../domain/models/product_summary.dart';
import '../../domain/models/transaction_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardMetrics> getMetrics(DashboardFilter filter) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network/db

    double multiplier = 1.0;
    if (filter == DashboardFilter.thisWeek) multiplier = 7.0;
    if (filter == DashboardFilter.thisMonth) multiplier = 30.0;

    return DashboardMetrics(
      revenue: 1250.0 * multiplier,
      ordersCount: (24 * multiplier).toInt(),
      estimatedProfit: 450.0 * multiplier,
      refunds: 25.0 * multiplier,
      expenses: 120.0 * multiplier,
      chartData: List.generate(7, (index) => (index + 1) * 100.0 * multiplier),
    );
  }

  @override
  Future<List<ProductSummary>> getLowStockProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ProductSummary(id: '1', name: 'Wireless Mouse', stockQuantity: 2, price: 25.0),
      ProductSummary(id: '2', name: 'Mechanical Keyboard', stockQuantity: 1, price: 120.0),
      ProductSummary(id: '3', name: 'USB-C Hub', stockQuantity: 5, price: 45.0),
    ];
  }

  @override
  Future<List<ProductSummary>> getTopSellingProducts(DashboardFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ProductSummary(id: '4', name: 'Monitor Stand', stockQuantity: 15, price: 35.0, soldQuantity: 42),
      ProductSummary(id: '5', name: 'Desk Mat', stockQuantity: 30, price: 20.0, soldQuantity: 38),
      ProductSummary(id: '6', name: 'Ergonomic Chair', stockQuantity: 8, price: 250.0, soldQuantity: 12),
    ];
  }

  @override
  Future<List<TransactionSummary>> getRecentTransactions(int limit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(
      limit,
      (index) => TransactionSummary(
        id: 'TRX-${1000 + index}',
        date: DateTime.now().subtract(Duration(minutes: index * 45)),
        total: 45.50 + (index * 12.0),
        status: index % 5 == 0 ? 'Refunded' : 'Completed',
      ),
    );
  }
}
