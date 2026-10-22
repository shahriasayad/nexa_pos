import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:nexa_pos/features/suppliers/presentation/screens/supplier_form_screen.dart';
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

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late SupplierController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SupplierController(repository: AppRepositories.instance.supplierRepo);
    _controller.loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openSupplierForm([String? id]) async {
    final supplier = id != null
        ? _controller.suppliers.firstWhere((s) => s.id == id)
        : null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
    );
    if (result == true) {
      _controller.loadSuppliers(query: _searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.suppliers,
      title: 'Suppliers',
      actions: [
        CustomButton(
          label: 'New Supplier',
          icon: Icons.add_business_rounded,
          variant: CustomButtonVariant.primary,
          height: 38,
          onPressed: () => _openSupplierForm(),
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
                  title: 'Suppliers & Vendors',
                  subtitle:
                      'Manage procurement partners, supply contracts, and vendor balances.',
                  actions: [
                    CustomButton(
                      label: 'New Supplier',
                      icon: Icons.add_business_rounded,
                      variant: CustomButtonVariant.primary,
                      height: 40,
                      onPressed: () => _openSupplierForm(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Top KPI Summary Cards
                _buildMetricsOverview(),
                const SizedBox(height: AppSpacing.lg),

                // Filter Toolbar
                PosFilterToolbar(
                  searchHint: 'Search suppliers by name, contact, email...',
                  searchValue: _searchController.text,
                  onSearchChanged: (val) {
                    _searchController.text = val;
                    _controller.loadSuppliers(query: val);
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    _controller.loadSuppliers();
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Content Area
                _buildSupplierContent(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final suppliers = _controller.suppliers;
    final total = suppliers.length;
    final active = suppliers.where((s) => s.isActive).length;
    final totalBalance = suppliers.fold<double>(
      0.0,
      (sum, s) => sum + s.outstandingBalance,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final count = isWide ? 3 : 1;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: isWide ? 2.5 : 3.0,
          children: [
            PosKpiCard(
              title: 'Active Suppliers',
              value: '$active / $total',
              icon: Icons.business_outlined,
              color: AppColors.primary,
            ),
            PosKpiCard(
              title: 'Total Outstanding Balance',
              value: '\$${totalBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_outlined,
              color: totalBalance > 0 ? AppColors.warning : AppColors.success,
            ),
            PosKpiCard(
              title: 'Vendor Directory Health',
              value: total > 0 ? '${((active / total) * 100).toInt()}% Active' : '0%',
              icon: Icons.health_and_safety_outlined,
              color: AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierContent(BuildContext context) {
    switch (_controller.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: LoadingView(message: 'Loading supplier directory...'),
        );
      case ViewState.error:
        return ErrorView(
          message: _controller.errorMessage ?? 'Error loading suppliers',
          onRetry: () => _controller.loadSuppliers(),
        );
      case ViewState.empty:
        return EmptyStateView(
          icon: Icons.business_center_outlined,
          title: 'No Suppliers Found',
          description: _searchController.text.isNotEmpty
              ? 'No vendor records matched "${_searchController.text}".'
              : 'Add your wholesale vendors and suppliers to begin tracking purchases.',
          actionLabel: 'Add First Supplier',
          onAction: () => _openSupplierForm(),
        );
      case ViewState.success:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;
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
        DataColumn(label: Text('Supplier Name')),
        DataColumn(label: Text('Contact Person')),
        DataColumn(label: Text('Contact Details')),
        DataColumn(label: Text('Outstanding Balance')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _controller.suppliers.map((supplier) {
        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.normal),
                    ),
                    child: const Icon(
                      Icons.store_mall_directory_outlined,
                      size: 18,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    supplier.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              onTap: () => _openSupplierForm(supplier.id),
            ),
            DataCell(
              Text(
                supplier.contactName ?? '—',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (supplier.phone != null)
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(supplier.phone!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  if (supplier.email != null)
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          supplier.email!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  if (supplier.phone == null && supplier.email == null)
                    const Text('—', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            DataCell(
              Text(
                '\$${supplier.outstandingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: supplier.outstandingBalance > 0
                      ? AppColors.warning
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
            DataCell(
              StatusBadge(
                label: supplier.isActive ? 'ACTIVE' : 'INACTIVE',
                type: supplier.isActive ? StatusType.success : StatusType.neutral,
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Supplier',
                onPressed: () => _openSupplierForm(supplier.id),
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
      itemCount: _controller.suppliers.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final supplier = _controller.suppliers[index];

        return CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InkWell(
            onTap: () => _openSupplierForm(supplier.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.normal),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_outlined,
                        color: AppColors.primaryStrong,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          if (supplier.contactName != null)
                            Text(
                              'Contact: ${supplier.contactName}',
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
                    StatusBadge(
                      label: supplier.isActive ? 'ACTIVE' : 'INACTIVE',
                      type: supplier.isActive
                          ? StatusType.success
                          : StatusType.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (supplier.phone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            supplier.phone!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        Text(
                          'Balance: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${supplier.outstandingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: supplier.outstandingBalance > 0
                                ? AppColors.warning
                                : AppColors.primary,
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
