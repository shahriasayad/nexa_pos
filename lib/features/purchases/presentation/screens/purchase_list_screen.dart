import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/purchases/domain/models/purchase_order.dart';
import 'package:nexa_pos/features/purchases/presentation/controllers/purchase_controller.dart';
import 'package:nexa_pos/features/purchases/presentation/screens/purchase_form_screen.dart';
import 'package:nexa_pos/features/purchases/presentation/screens/receive_purchase_screen.dart';
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

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  late PurchaseController _controller;
  String _searchQuery = '';
  PurchaseStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _controller = PurchaseController(
      purchaseRepo: AppRepositories.instance.purchaseRepo,
      inventoryRepo: AppRepositories.instance.inventoryRepo,
      productRepo: AppRepositories.instance.productRepo,
    );
    _controller.loadPurchases();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPurchaseForm([PurchaseOrder? purchase]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PurchaseFormScreen(purchase: purchase)),
    );
    if (result == true) {
      _controller.loadPurchases();
    }
  }

  void _receivePurchase(PurchaseOrder purchase) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceivePurchaseScreen(purchase: purchase),
      ),
    );
    if (result == true) {
      _controller.loadPurchases();
    }
  }

  StatusType _getStatusBadgeType(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.draft:
        return StatusType.neutral;
      case PurchaseStatus.ordered:
        return StatusType.warning;
      case PurchaseStatus.received:
        return StatusType.success;
      case PurchaseStatus.cancelled:
        return StatusType.danger;
    }
  }

  List<PurchaseOrder> _getFilteredPurchases() {
    return _controller.purchases.where((po) {
      final matchesSearch = _searchQuery.isEmpty ||
          po.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          po.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == null || po.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.purchases,
      title: 'Purchases',
      actions: [
        CustomButton(
          label: 'New Purchase Order',
          icon: Icons.add_shopping_cart_rounded,
          variant: CustomButtonVariant.primary,
          height: 38,
          onPressed: () => _openPurchaseForm(),
        ),
      ],
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final filtered = _getFilteredPurchases();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPageHeader(
                  title: 'Purchase Orders & Inbound Stock',
                  subtitle:
                      'Draft purchase orders, track procurement from suppliers, and intake inventory.',
                  actions: [
                    CustomButton(
                      label: 'New Purchase Order',
                      icon: Icons.add_shopping_cart_rounded,
                      variant: CustomButtonVariant.primary,
                      height: 40,
                      onPressed: () => _openPurchaseForm(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Top KPI Metrics
                _buildMetricsOverview(),
                const SizedBox(height: AppSpacing.lg),

                // Filter Toolbar with status chips
                PosFilterToolbar(
                  searchHint: 'Search POs by number or supplier name...',
                  searchValue: _searchQuery,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onClearSearch: () => setState(() => _searchQuery = ''),
                  filters: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...PurchaseStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(status.name.toUpperCase()),
                          selected: _statusFilter == status,
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter = selected ? status : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Content View
                _buildPurchaseContent(context, filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final purchases = _controller.purchases;
    final total = purchases.length;
    final pendingReceipt =
        purchases.where((p) => p.status == PurchaseStatus.ordered).length;
    final totalSpend = purchases.fold<double>(
      0.0,
      (sum, p) => sum + p.totalAmount,
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
              title: 'Total Purchase Orders',
              value: '$total',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
            PosKpiCard(
              title: 'Awaiting Receipt',
              value: '$pendingReceipt POs',
              icon: Icons.local_shipping_outlined,
              color: pendingReceipt > 0 ? AppColors.warning : AppColors.success,
            ),
            PosKpiCard(
              title: 'Total Procurement Value',
              value: '\$${totalSpend.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseContent(BuildContext context, List<PurchaseOrder> purchases) {
    if (_controller.state == ViewState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(message: 'Loading purchase orders...'),
      );
    }
    if (_controller.state == ViewState.error) {
      return ErrorView(
        message: _controller.errorMessage ?? 'Error loading purchases',
        onRetry: () => _controller.loadPurchases(),
      );
    }
    if (purchases.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_outlined,
        title: 'No Purchase Orders',
        description: _searchQuery.isNotEmpty || _statusFilter != null
            ? 'No purchase orders matched your search and filter criteria.'
            : 'Create your first purchase order to restock store inventory.',
        actionLabel: 'Create Purchase Order',
        onAction: () => _openPurchaseForm(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        if (isDesktop) {
          return _buildDesktopTable(context, purchases);
        } else {
          return _buildMobileCardList(context, purchases);
        }
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<PurchaseOrder> purchases) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PosDataTable(
      columns: const [
        DataColumn(label: Text('PO Number')),
        DataColumn(label: Text('Supplier')),
        DataColumn(label: Text('Order Date')),
        DataColumn(label: Text('Items')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: purchases.map((po) {
        final dateStr =
            '${po.orderDate.year}-${po.orderDate.month.toString().padLeft(2, '0')}-${po.orderDate.day.toString().padLeft(2, '0')}';

        return DataRow(
          cells: [
            DataCell(
              Text(
                'PO-${po.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              onTap: () {
                if (po.status == PurchaseStatus.draft) {
                  _openPurchaseForm(po);
                } else if (po.status == PurchaseStatus.ordered) {
                  _receivePurchase(po);
                }
              },
            ),
            DataCell(
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    po.supplierName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
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
                '${po.items.length} line item(s)',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            DataCell(
              Text(
                '\$${po.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.primary,
                ),
              ),
            ),
            DataCell(
              StatusBadge(
                label: po.status.name.toUpperCase(),
                type: _getStatusBadgeType(po.status),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (po.status == PurchaseStatus.draft)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Draft PO',
                      onPressed: () => _openPurchaseForm(po),
                    ),
                  if (po.status == PurchaseStatus.ordered)
                    CustomButton(
                      label: 'Receive',
                      icon: Icons.inventory_2_outlined,
                      variant: CustomButtonVariant.primary,
                      height: 28,
                      onPressed: () => _receivePurchase(po),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileCardList(BuildContext context, List<PurchaseOrder> purchases) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: purchases.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final po = purchases[index];
        final dateStr =
            '${po.orderDate.year}-${po.orderDate.month.toString().padLeft(2, '0')}-${po.orderDate.day.toString().padLeft(2, '0')}';

        return CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PO-${po.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  StatusBadge(
                    label: po.status.name.toUpperCase(),
                    type: _getStatusBadgeType(po.status),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    po.supplierName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${po.items.length} line item(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${po.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (po.status == PurchaseStatus.draft ||
                  po.status == PurchaseStatus.ordered) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (po.status == PurchaseStatus.draft)
                      CustomButton(
                        label: 'Edit Draft',
                        icon: Icons.edit_outlined,
                        variant: CustomButtonVariant.outline,
                        height: 34,
                        onPressed: () => _openPurchaseForm(po),
                      ),
                    if (po.status == PurchaseStatus.ordered)
                      CustomButton(
                        label: 'Receive Stock',
                        icon: Icons.inventory_2_outlined,
                        variant: CustomButtonVariant.primary,
                        height: 34,
                        onPressed: () => _receivePurchase(po),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
