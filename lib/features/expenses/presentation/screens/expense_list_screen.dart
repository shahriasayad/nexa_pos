import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/expenses/data/repositories/mock_expense_repository.dart';
import 'package:nexa_pos/features/expenses/domain/models/expense.dart';
import 'package:nexa_pos/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:nexa_pos/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/data_table_view.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/filter_toolbar.dart';
import 'package:nexa_pos/shared/widgets/kpi_card.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late ExpenseController _controller;
  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = ExpenseController(repository: MockExpenseRepository());
    _controller.loadExpenses();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openExpenseForm([Expense? expense]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
    if (result == true) {
      _controller.loadExpenses(category: _selectedCategory);
    }
  }

  void _onCategoryChanged(ExpenseCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _controller.loadExpenses(category: category);
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.apartment_outlined;
      case ExpenseCategory.electricity:
        return Icons.bolt_outlined;
      case ExpenseCategory.internet:
        return Icons.wifi_outlined;
      case ExpenseCategory.salary:
        return Icons.payments_outlined;
      case ExpenseCategory.transportation:
        return Icons.local_shipping_outlined;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.other:
        return Icons.receipt_outlined;
    }
  }

  List<Expense> _getFilteredExpenses() {
    return _controller.expenses.where((exp) {
      if (_searchQuery.isEmpty) return true;
      return exp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (exp.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.expenses,
      title: 'Expenses',
      actions: [
        CustomButton(
          label: 'Add Expense',
          icon: Icons.add_circle_outline_rounded,
          variant: CustomButtonVariant.primary,
          height: 38,
          onPressed: () => _openExpenseForm(),
        ),
      ],
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final filtered = _getFilteredExpenses();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPageHeader(
                  title: 'Expense Management',
                  subtitle:
                      'Track overhead, operational utility bills, supplier disbursements, and staff expenses.',
                  actions: [
                    CustomButton(
                      label: 'Add Expense',
                      icon: Icons.add_circle_outline_rounded,
                      variant: CustomButtonVariant.primary,
                      height: 40,
                      onPressed: () => _openExpenseForm(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Top KPI Summary Cards
                _buildMetricsOverview(),
                const SizedBox(height: AppSpacing.lg),

                // Filter Toolbar with category filter chips
                PosFilterToolbar(
                  searchHint: 'Search expenses by description or note...',
                  searchValue: _searchQuery,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onClearSearch: () => setState(() => _searchQuery = ''),
                  filters: [
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategory == null,
                      onSelected: (val) {
                        if (val) _onCategoryChanged(null);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...ExpenseCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          avatar: Icon(_getCategoryIcon(cat), size: 14),
                          label: Text(cat.displayName),
                          selected: _selectedCategory == cat,
                          onSelected: (val) {
                            _onCategoryChanged(val ? cat : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Content View
                _buildExpenseContent(context, filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final total = _controller.totalExpenses;
    final count = _controller.expenses.length;

    // Calculate largest expense category
    final categoryTotals = <ExpenseCategory, double>{};
    for (var exp in _controller.expenses) {
      categoryTotals[exp.category] =
          (categoryTotals[exp.category] ?? 0) + exp.amount;
    }
    var topCategory = 'None';
    if (categoryTotals.isNotEmpty) {
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key.displayName;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final gridCount = isWide ? 3 : 1;

        return GridView.count(
          crossAxisCount: gridCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: isWide ? 2.5 : 3.0,
          children: [
            PosKpiCard(
              title: 'Total Operating Expenses',
              value: '\$${total.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.danger,
            ),
            PosKpiCard(
              title: 'Expense Entries',
              value: '$count records',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
            PosKpiCard(
              title: 'Top Cost Driver',
              value: topCategory,
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseContent(BuildContext context, List<Expense> expenses) {
    if (_controller.state == ViewState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(message: 'Loading expense entries...'),
      );
    }
    if (_controller.state == ViewState.error) {
      return ErrorView(
        message: _controller.errorMessage ?? 'Error loading expenses',
        onRetry: () => _controller.loadExpenses(category: _selectedCategory),
      );
    }
    if (expenses.isEmpty) {
      return EmptyStateView(
        icon: Icons.money_off_csred_outlined,
        title: 'No Expenses Found',
        description: _selectedCategory != null || _searchQuery.isNotEmpty
            ? 'No expenses matched your search or category filter.'
            : 'Record rent, utilities, and store operational costs to balance your cash flow.',
        actionLabel: 'Record First Expense',
        onAction: () => _openExpenseForm(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        if (isDesktop) {
          return _buildDesktopTable(context, expenses);
        } else {
          return _buildMobileCardList(context, expenses);
        }
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<Expense> expenses) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PosDataTable(
      columns: const [
        DataColumn(label: Text('Expense Title')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Notes / Memo')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Actions')),
      ],
      rows: expenses.map((exp) {
        final dateStr =
            '${exp.date.year}-${exp.date.month.toString().padLeft(2, '0')}-${exp.date.day.toString().padLeft(2, '0')}';

        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.normal),
                    ),
                    child: Icon(
                      _getCategoryIcon(exp.category),
                      size: 16,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    exp.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              onTap: () => _openExpenseForm(exp),
            ),
            DataCell(
              StatusBadge(
                label: exp.category.displayName.toUpperCase(),
                type: StatusType.neutral,
              ),
            ),
            DataCell(
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            DataCell(
              Text(
                exp.note != null && exp.note!.isNotEmpty ? exp.note! : '—',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
            DataCell(
              Text(
                '-\$${exp.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.danger,
                ),
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Expense',
                onPressed: () => _openExpenseForm(exp),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileCardList(BuildContext context, List<Expense> expenses) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final dateStr =
            '${exp.date.year}-${exp.date.month.toString().padLeft(2, '0')}-${exp.date.day.toString().padLeft(2, '0')}';

        return CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InkWell(
            onTap: () => _openExpenseForm(exp),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.normal),
                  ),
                  child: Icon(
                    _getCategoryIcon(exp.category),
                    color: AppColors.danger,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            exp.category.displayName,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• $dateStr',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '-\$${exp.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
