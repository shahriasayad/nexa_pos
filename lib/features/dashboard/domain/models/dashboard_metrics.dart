class DashboardMetrics {
  final double revenue;
  final int ordersCount;
  final double estimatedProfit;
  final double refunds;
  final double expenses;
  final List<double> chartData;

  DashboardMetrics({
    required this.revenue,
    required this.ordersCount,
    required this.estimatedProfit,
    required this.refunds,
    required this.expenses,
    required this.chartData,
  });
}
