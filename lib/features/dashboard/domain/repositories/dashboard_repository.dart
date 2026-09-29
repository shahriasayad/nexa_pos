import '../models/dashboard_metrics.dart';
import '../models/product_summary.dart';
import '../models/transaction_summary.dart';

enum DashboardFilter { today, thisWeek, thisMonth }

abstract class DashboardRepository {
  Future<DashboardMetrics> getMetrics(DashboardFilter filter);
  Future<List<ProductSummary>> getLowStockProducts();
  Future<List<ProductSummary>> getTopSellingProducts(DashboardFilter filter);
  Future<List<TransactionSummary>> getRecentTransactions(int limit);
}
