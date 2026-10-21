import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/dashboard/data/repositories/mock_dashboard_repository.dart';
import 'package:nexa_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nexa_pos/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nexa_pos/features/dashboard/presentation/widgets/recent_transactions_list.dart';
import 'package:nexa_pos/features/dashboard/presentation/widgets/sales_chart.dart';
import 'package:nexa_pos/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:nexa_pos/features/dashboard/presentation/widgets/top_products_list.dart';
import 'package:nexa_pos/features/expenses/data/repositories/mock_expense_repository.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

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
    return AppShell(
      title: 'Nexa POS - Dashboard',
      actions: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final filter = _controller.currentFilter;
            return Container(
              height: 38,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.normal),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterTab('Today', DashboardFilter.today, filter),
                  _buildFilterTab('This Week', DashboardFilter.thisWeek, filter),
                  _buildFilterTab('This Month', DashboardFilter.thisMonth, filter),
                ],
              ),
            );
          },
        ),
      ],
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          switch (_controller.state) {
            case ViewState.initial:
            case ViewState.loading:
              return const LoadingView(message: 'Loading Dashboard data...');
            case ViewState.error:
              return ErrorView(
                message: _controller.errorMessage ?? 'Failed to load dashboard',
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

  Widget _buildFilterTab(
    String label,
    DashboardFilter value,
    DashboardFilter selected,
  ) {
    final isSelected = value == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.small),
      onTap: () => _controller.setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _controller.loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildKpiSection(bool isMobile) {
    final metrics = _controller.metrics!;

    if (isMobile) {
      return Column(
        children: [
          StatCard(
            title: 'Total Revenue',
            value: '\$${metrics.revenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            iconColor: AppColors.success,
            isHero: true,
            subtitle: '${metrics.ordersCount} orders completed',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Orders',
                  value: '${metrics.ordersCount}',
                  icon: Icons.receipt_long,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Est. Profit',
                  value: '\$${metrics.estimatedProfit.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  iconColor: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Refunds',
                  value: '\$${metrics.refunds.toStringAsFixed(2)}',
                  icon: Icons.keyboard_return,
                  iconColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Low Stock',
                  value: '${_controller.lowStockProducts.length}',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Tablet & Desktop: Deliberate hierarchy with hero revenue card + 4 supporting KPI cards
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: StatCard(
            title: 'Total Revenue',
            value: '\$${metrics.revenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            iconColor: AppColors.success,
            isHero: true,
            subtitle: '${metrics.ordersCount} completed orders in selected period',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 1,
          child: StatCard(
            title: 'Orders',
            value: '${metrics.ordersCount}',
            icon: Icons.receipt_long,
            iconColor: AppColors.info,
            subtitle: 'Transaction count',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 1,
          child: StatCard(
            title: 'Est. Profit',
            value: '\$${metrics.estimatedProfit.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            iconColor: AppColors.purple,
            subtitle: 'Net after costs',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 1,
          child: StatCard(
            title: 'Refunds',
            value: '\$${metrics.refunds.toStringAsFixed(2)}',
            icon: Icons.keyboard_return,
            iconColor: AppColors.danger,
            subtitle: 'Total returned',
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildKpiSection(true),
        const SizedBox(height: AppSpacing.lg),
        SalesChart(metrics: _controller.metrics!),
        const SizedBox(height: AppSpacing.lg),
        RecentTransactionsList(transactions: _controller.recentTransactions),
        const SizedBox(height: AppSpacing.lg),
        TopProductsList(
          title: 'Top Selling Products',
          products: _controller.topProducts,
        ),
        const SizedBox(height: AppSpacing.lg),
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
        _buildKpiSection(false),
        const SizedBox(height: AppSpacing.xl),
        SalesChart(metrics: _controller.metrics!),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: RecentTransactionsList(
                transactions: _controller.recentTransactions,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  TopProductsList(
                    title: 'Top Selling Products',
                    products: _controller.topProducts,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TopProductsList(
                    title: 'Low Stock Alerts',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildKpiSection(false),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left main column: Revenue trend chart & Recent transactions
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SalesChart(metrics: _controller.metrics!),
                  const SizedBox(height: AppSpacing.xl),
                  RecentTransactionsList(
                    transactions: _controller.recentTransactions,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Right analytics column: Top products & Low stock alerts
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  TopProductsList(
                    title: 'Top Selling Products',
                    products: _controller.topProducts,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TopProductsList(
                    title: 'Low Stock Alerts',
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
}
