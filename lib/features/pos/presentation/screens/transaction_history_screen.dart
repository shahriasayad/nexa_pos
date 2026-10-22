import 'package:flutter/material.dart';
import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/transaction_history_controller.dart';
import 'package:nexa_pos/features/pos/presentation/screens/transaction_details_screen.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late TransactionHistoryController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TransactionHistoryController(
      salesRepo: AppRepositories.instance.salesRepo,
    );
    _controller.loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: (_controller.startDate != null && _controller.endDate != null)
          ? DateTimeRange(start: _controller.startDate!, end: _controller.endDate!)
          : null,
    );

    if (picked != null) {
      _controller.setFilters(
        search: _searchController.text,
        start: picked.start,
        end: picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
        method: _controller.paymentMethod,
        status: _controller.status,
      );
    }
  }

  void _navigateToDetails(String transactionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          transactionId: transactionId,
          salesRepo: _controller.salesRepo as MockSalesRepository,
        ),
      ),
    ).then((_) {
      if (mounted) _controller.loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Sales History',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _controller.loadTransactions,
        ),
      ],
      child: Column(
        children: [
          _buildFilterToolbar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    Widget searchField = SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Search by Transaction ID or Customer...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearFilters();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
        ),
        onChanged: (v) => _controller.setFilters(
          search: v,
          start: _controller.startDate,
          end: _controller.endDate,
          method: _controller.paymentMethod,
          status: _controller.status,
        ),
      ),
    );

    final dropdownFilters = [
      // Payment Method Filter
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.normal),
          color: isDark ? AppColors.darkSurface : AppColors.surface,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<PaymentMethod?>(
            value: _controller.paymentMethod,
            hint: const Text('All Payments', style: TextStyle(fontSize: 12.5)),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Payments')),
              ...PaymentMethod.values.map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: (v) => _controller.setFilters(
              search: _searchController.text,
              start: _controller.startDate,
              end: _controller.endDate,
              method: v,
              status: _controller.status,
            ),
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          ),
        ),
      ),

      // Date Range Button
      OutlinedButton.icon(
        onPressed: _openDateRangePicker,
        icon: const Icon(Icons.date_range, size: 16),
        label: Text(
          _controller.startDate != null
              ? '${_controller.startDate!.month}/${_controller.startDate!.day} - ${_controller.endDate!.month}/${_controller.endDate!.day}'
              : 'Date Range',
          style: const TextStyle(fontSize: 12.5),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.normal),
          ),
        ),
      ),

      if (_controller.startDate != null ||
          _controller.paymentMethod != null ||
          _searchController.text.isNotEmpty)
        TextButton(
          onPressed: () {
            _searchController.clear();
            _controller.clearFilters();
          },
          child: const Text('Reset', style: TextStyle(fontSize: 12)),
        ),
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dropdownFilters.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: w,
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: searchField),
                const SizedBox(width: AppSpacing.md),
                ...dropdownFilters.map((w) {
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: w,
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildBody() {
    switch (_controller.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const LoadingView(message: 'Loading transaction records...');
      case ViewState.error:
        return ErrorView(
          message: 'Failed to load transactions',
          onRetry: _controller.loadTransactions,
        );
      case ViewState.empty:
        return const EmptyStateView(
          message: 'No sales transactions found',
          icon: Icons.receipt_long_outlined,
        );
      case ViewState.success:
        return CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (!ResponsiveLayout.isMobile(context)) _buildTableHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: _controller.transactions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    final sale = _controller.transactions[index];
                    return _buildTransactionRow(sale);
                  },
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('TRANSACTION ID')),
          Expanded(flex: 2, child: _HeaderCell('DATE & TIME')),
          Expanded(flex: 2, child: _HeaderCell('CUSTOMER')),
          Expanded(flex: 1, child: _HeaderCell('ITEMS')),
          Expanded(flex: 1, child: _HeaderCell('PAYMENT')),
          Expanded(flex: 1, child: _HeaderCell('STATUS')),
          Expanded(flex: 1, child: _HeaderCell('TOTAL', alignment: TextAlign.right)),
          SizedBox(width: 80, child: _HeaderCell('ACTION', alignment: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(SaleTransaction sale) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRefunded = sale.status == SaleStatus.refunded;
    final isPartiallyRefunded = sale.returns.isNotEmpty && !isRefunded;

    final dateStr =
        '${sale.timestamp.month}/${sale.timestamp.day} ${sale.timestamp.hour.toString().padLeft(2, '0')}:${sale.timestamp.minute.toString().padLeft(2, '0')}';

    final totalItems = sale.items.fold<int>(0, (sum, i) => sum + i.quantity);

    if (isMobile) {
      return InkWell(
        onTap: () => _navigateToDetails(sale.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRX-${sale.id.length > 8 ? sale.id.substring(sale.id.length - 8) : sale.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  Text(
                    '\$${sale.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isRefunded ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sale.customerName ?? 'Walk-in'} • $totalItems items',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: sale.status.name.toUpperCase(),
                        type: isRefunded
                            ? BadgeType.danger
                            : (isPartiallyRefunded
                                ? BadgeType.warning
                                : BadgeType.success),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        sale.paymentMethod.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _navigateToDetails(sale.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    isRefunded
                        ? Icons.keyboard_return
                        : Icons.receipt_long_outlined,
                    size: 16,
                    color: isRefunded ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'TRX-${sale.id.length > 8 ? sale.id.substring(sale.id.length - 8) : sale.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                sale.customerName ?? 'Walk-in Customer',
                style: const TextStyle(fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '$totalItems',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                sale.paymentMethod.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: sale.status.name.toUpperCase(),
                  type: isRefunded
                      ? BadgeType.danger
                      : (isPartiallyRefunded
                          ? BadgeType.warning
                          : BadgeType.success),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '\$${sale.total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isRefunded ? AppColors.danger : AppColors.primary,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'View Transaction',
                  onPressed: () => _navigateToDetails(sale.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign alignment;

  const _HeaderCell(this.text, {this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      textAlign: alignment,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }
}
