import '../../domain/models/dashboard_metrics.dart';
import '../../domain/models/product_summary.dart';
import '../../domain/models/transaction_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../pos/domain/repositories/sales_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  final SalesRepository salesRepo;
  final ProductRepository productRepo;

  MockDashboardRepository({
    required this.salesRepo,
    required this.productRepo,
  });

  DateTime _getStartDateForFilter(DashboardFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case DashboardFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DashboardFilter.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case DashboardFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
    }
  }

  @override
  Future<DashboardMetrics> getMetrics(DashboardFilter filter) async {
    final startDate = _getStartDateForFilter(filter);
    final sales = await salesRepo.getSales(startDate: startDate);
    
    double revenue = 0.0;
    for (var s in sales) {
      revenue += s.total;
    }
    
    // Simplistic chart data generation based on actual revenue
    List<double> chartData = List.generate(7, (i) => 0.0);
    if (sales.isNotEmpty) {
      chartData[6] = revenue; // Just put it all on the last day for now to satisfy the model
    }

    return DashboardMetrics(
      revenue: revenue,
      ordersCount: sales.length,
      estimatedProfit: revenue * 0.3, // Mock profit margin 30%
      refunds: 0.0,
      expenses: 0.0,
      chartData: chartData,
    );
  }

  @override
  Future<List<ProductSummary>> getLowStockProducts() async {
    final allProducts = await productRepo.getProducts();
    final lowStock = allProducts.where((p) => p.stockQuantity <= p.minimumStock).toList();
    return lowStock.map((p) => ProductSummary(
      id: p.id,
      name: p.name,
      stockQuantity: p.stockQuantity,
      price: p.sellingPrice,
    )).toList();
  }

  @override
  Future<List<ProductSummary>> getTopSellingProducts(DashboardFilter filter) async {
    final startDate = _getStartDateForFilter(filter);
    final sales = await salesRepo.getSales(startDate: startDate);
    
    Map<String, int> productSales = {};
    for (var sale in sales) {
      for (var item in sale.items) {
        productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
      }
    }

    final allProducts = await productRepo.getProducts();
    
    var topSelling = productSales.entries.map((e) {
      final p = allProducts.where((prod) => prod.id == e.key).firstOrNull;
      return ProductSummary(
        id: p?.id ?? e.key,
        name: p?.name ?? 'Unknown Product',
        stockQuantity: p?.stockQuantity ?? 0,
        price: p?.sellingPrice ?? 0.0,
        soldQuantity: e.value,
      );
    }).toList();
    
    topSelling.sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));
    
    return topSelling.take(5).toList();
  }

  @override
  Future<List<TransactionSummary>> getRecentTransactions(int limit) async {
    final sales = await salesRepo.getSales();
    return sales.take(limit).map((s) => TransactionSummary(
      id: s.id,
      date: s.timestamp,
      total: s.total,
      status: s.status.name.toUpperCase(),
    )).toList();
  }
}
