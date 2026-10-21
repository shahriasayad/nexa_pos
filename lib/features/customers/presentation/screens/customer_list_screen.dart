import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/customers/data/repositories/mock_customer_repository.dart';
import 'package:nexa_pos/features/customers/domain/models/customer.dart';
import 'package:nexa_pos/features/customers/presentation/controllers/customer_controller.dart';
import 'package:nexa_pos/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/data_table_view.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/filter_toolbar.dart';
import 'package:nexa_pos/shared/widgets/kpi_card.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late CustomerController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CustomerController(repository: MockCustomerRepository());
    _controller.loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openCustomerForm([Customer? customer]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomerFormScreen(customer: customer, controller: _controller),
      ),
    );
    if (result == true) {
      _controller.loadCustomers(query: _searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.customers,
      title: 'Customers',
      actions: [
        CustomButton(
          label: 'New Customer',
          icon: Icons.person_add_alt_1_rounded,
          variant: CustomButtonVariant.primary,
          height: 38,
          onPressed: () => _openCustomerForm(),
        ),
      ],
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPageHeader(
                  title: 'Customers Directory',
                  subtitle:
                      'Manage retail customer accounts, contact details, and customer loyalty.',
                  actions: [
                    CustomButton(
                      label: 'New Customer',
                      icon: Icons.person_add_alt_1_rounded,
                      variant: CustomButtonVariant.primary,
                      height: 40,
                      onPressed: () => _openCustomerForm(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Top KPI Summary Cards
                _buildMetricsOverview(),
                const SizedBox(height: AppSpacing.lg),

                // Filter Toolbar
                PosFilterToolbar(
                  searchHint: 'Search by customer name, phone, or email...',
                  searchValue: _searchController.text,
                  onSearchChanged: (val) {
                    _searchController.text = val;
                    _controller.loadCustomers(query: val);
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    _controller.loadCustomers();
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Content Area
                _buildCustomerContent(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final customers = _controller.customers;
    final totalCustomers = customers.length;
    final totalSpent = customers.fold<double>(
      0.0,
      (sum, c) => sum + c.totalSpending,
    );
    final totalPoints = customers.fold<int>(
      0,
      (sum, c) => sum + c.loyaltyPoints,
    );
    final totalBalance = customers.fold<double>(
      0.0,
      (sum, c) => sum + c.outstandingBalance,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final count = isWide ? 4 : 2;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: isWide ? 2.3 : 1.7,
          children: [
            PosKpiCard(
              title: 'Total Customers',
              value: '$totalCustomers',
              icon: Icons.people_alt_outlined,
              color: AppColors.primary,
            ),
            PosKpiCard(
              title: 'Total Revenue',
              value: '\$${totalSpent.toStringAsFixed(2)}',
              icon: Icons.point_of_sale_outlined,
              color: AppColors.success,
            ),
            PosKpiCard(
              title: 'Loyalty Points',
              value: '$totalPoints pts',
              icon: Icons.stars_rounded,
              color: AppColors.orange,
            ),
            PosKpiCard(
              title: 'Outstanding Balance',
              value: '\$${totalBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              color: totalBalance > 0 ? AppColors.warning : AppColors.textMuted,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerContent(BuildContext context) {
    switch (_controller.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: LoadingView(message: 'Loading customer directory...'),
        );
      case ViewState.error:
        return ErrorView(
          message: _controller.errorMessage ?? 'Failed to load customers',
          onRetry: () => _controller.loadCustomers(),
        );
      case ViewState.empty:
        return EmptyStateView(
          icon: Icons.person_search_outlined,
          title: 'No Customers Found',
          description: _searchController.text.isNotEmpty
              ? 'No customer records matched "${_searchController.text}".'
              : 'Start building customer relationships by registering your first customer.',
          actionLabel: 'Add First Customer',
          onAction: () => _openCustomerForm(),
        );
      case ViewState.success:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;
            if (isDesktop) {
              return _buildDesktopTable(context);
            } else {
              return _buildMobileCardList(context);
            }
          },
        );
    }
  }

  Widget _buildDesktopTable(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PosDataTable(
      columns: const [
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Contact')),
        DataColumn(label: Text('Loyalty Points')),
        DataColumn(label: Text('Balance')),
        DataColumn(label: Text('Total Spend')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _controller.customers.map((customer) {
        final initials = customer.name.isNotEmpty
            ? customer.name
                .trim()
                .split(' ')
                .take(2)
                .map((e) => e.isNotEmpty ? e[0] : '')
                .join()
                .toUpperCase()
            : '?';

        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryStrong,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (customer.address != null &&
                          customer.address!.isNotEmpty)
                        Text(
                          customer.address!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () => _openCustomerForm(customer),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(customer.phone!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  if (customer.email != null && customer.email!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          customer.email!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  if ((customer.phone == null || customer.phone!.isEmpty) &&
                      (customer.email == null || customer.email!.isEmpty))
                    const Text('—', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            DataCell(
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.loyaltyPoints} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                '\$${customer.outstandingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: customer.outstandingBalance > 0
                      ? AppColors.warning
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
            DataCell(
              Text(
                '\$${customer.totalSpending.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Customer',
                onPressed: () => _openCustomerForm(customer),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileCardList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _controller.customers.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final customer = _controller.customers[index];
        final initials = customer.name.isNotEmpty
            ? customer.name
                .trim()
                .split(' ')
                .take(2)
                .map((e) => e.isNotEmpty ? e[0] : '')
                .join()
                .toUpperCase()
            : '?';

        return CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InkWell(
            onTap: () => _openCustomerForm(customer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      radius: 20,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          if (customer.phone != null &&
                              customer.phone!.isNotEmpty)
                            Text(
                              customer.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _openCustomerForm(customer),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 16, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${customer.loyaltyPoints} pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Total Spend: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${customer.totalSpending.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
