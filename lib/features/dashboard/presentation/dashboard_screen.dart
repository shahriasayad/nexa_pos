import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../products/data/repositories/mock_product_repository.dart';
import '../../pos/data/repositories/mock_sales_repository.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../data/repositories/mock_dashboard_repository.dart';
import '../domain/repositories/dashboard_repository.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/stat_card.dart';
import 'widgets/sales_chart.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/top_products_list.dart';

import '../../../../core/layout/app_drawer.dart';
import '../../expenses/data/repositories/mock_expense_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(
      repository: MockDashboardRepository(
        salesRepo: MockSalesRepository(),
        productRepo: MockProductRepository(),
        expenseRepo: MockExpenseRepository(),
      ),
    );
    _controller.loadDashboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Nexa POS - Dashboard'),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButton<DashboardFilter>(
                  value: _controller.currentFilter,
                  onChanged: (DashboardFilter? newValue) {
                    if (newValue != null) {
                      _controller.setFilter(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: DashboardFilter.today,
                      child: Text('Today'),
                    ),
                    DropdownMenuItem(
                      value: DashboardFilter.thisWeek,
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: DashboardFilter.thisMonth,
                      child: Text('This Month'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          switch (_controller.state) {
            case ViewState.initial:
            case ViewState.loading:
              return const LoadingView(message: 'Loading Dashboard...');
            case ViewState.error:
              return ErrorView(
                message: _controller.errorMessage ?? 'Unknown error',
                onRetry: _controller.loadDashboardData,
              );
            case ViewState.empty:
            case ViewState.success:
              return _buildDashboardContent(context);
          }
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _controller.loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(int crossAxisCount, {double childAspectRatio = 1.5}) {
    final metrics = _controller.metrics!;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio,
      children: [
        StatCard(
          title: 'Revenue',
          value: '\$${metrics.revenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          iconColor: Colors.green,
        ),
        StatCard(
          title: 'Orders',
          value: '${metrics.ordersCount}',
          icon: Icons.receipt_long,
          iconColor: Colors.blue,
        ),
        StatCard(
          title: 'Est. Profit',
          value: '\$${metrics.estimatedProfit.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          iconColor: Colors.purple,
        ),
        StatCard(
          title: 'Refunds',
          value: '\$${metrics.refunds.toStringAsFixed(2)}',
          icon: Icons.keyboard_return,
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMetricsGrid(2),
        const SizedBox(height: 16),
        SalesChart(metrics: _controller.metrics!),
        const SizedBox(height: 16),
        RecentTransactionsList(transactions: _controller.recentTransactions),
        const SizedBox(height: 16),
        TopProductsList(
          title: 'Top Selling Products',
          products: _controller.topProducts,
        ),
        const SizedBox(height: 16),
        TopProductsList(
          title: 'Low Stock Alerts',
          products: _controller.lowStockProducts,
          isLowStock: true,
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMetricsGrid(4),
        const SizedBox(height: 16),
        SalesChart(metrics: _controller.metrics!),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: RecentTransactionsList(transactions: _controller.recentTransactions),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  TopProductsList(
                    title: 'Top Selling',
                    products: _controller.topProducts,
                  ),
                  const SizedBox(height: 16),
                  TopProductsList(
                    title: 'Low Stock',
                    products: _controller.lowStockProducts,
                    isLowStock: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMetricsGrid(4),
              const SizedBox(height: 16),
              SalesChart(metrics: _controller.metrics!),
              const SizedBox(height: 16),
              RecentTransactionsList(transactions: _controller.recentTransactions),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              TopProductsList(
                title: 'Top Selling Products',
                products: _controller.topProducts,
              ),
              const SizedBox(height: 16),
              TopProductsList(
                title: 'Low Stock Alerts',
                products: _controller.lowStockProducts,
                isLowStock: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
