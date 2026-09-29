import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/dashboard_metrics.dart';
import '../../domain/models/product_summary.dart';
import '../../domain/models/transaction_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  final DashboardRepository repository;

  DashboardController({required this.repository});

  ViewState state = ViewState.initial;
  String? errorMessage;

  DashboardFilter currentFilter = DashboardFilter.today;

  DashboardMetrics? metrics;
  List<ProductSummary> lowStockProducts = [];
  List<ProductSummary> topProducts = [];
  List<TransactionSummary> recentTransactions = [];

  Future<void> loadDashboardData() async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getMetrics(currentFilter),
        repository.getLowStockProducts(),
        repository.getTopSellingProducts(currentFilter),
        repository.getRecentTransactions(5),
      ]);

      metrics = results[0] as DashboardMetrics;
      lowStockProducts = results[1] as List<ProductSummary>;
      topProducts = results[2] as List<ProductSummary>;
      recentTransactions = results[3] as List<TransactionSummary>;

      state = ViewState.success;
    } catch (e) {
      state = ViewState.error;
      errorMessage = 'Failed to load dashboard data: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  void setFilter(DashboardFilter filter) {
    if (currentFilter != filter) {
      currentFilter = filter;
      loadDashboardData();
    }
  }
}
