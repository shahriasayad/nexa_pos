import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/pos/presentation/screens/receipt_dialog.dart';
import 'package:nexa_pos/features/returns/domain/models/return_transaction.dart';
import 'package:nexa_pos/features/returns/presentation/screens/return_dialog.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String transactionId;
  final MockSalesRepository salesRepo;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    required this.salesRepo,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  SaleTransaction? _sale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    setState(() => _isLoading = true);
    final sale = await widget.salesRepo.getSale(widget.transactionId);
    if (mounted) {
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    }
  }

  bool get _isFullyReturned {
    if (_sale == null) return false;
    for (var item in _sale!.items) {
      if (item.returnedQuantity < item.quantity) {
        return false;
      }
    }
    return true;
  }

  void _showReturnDialog() async {
    if (_sale == null) return;

    if (_isFullyReturned || _sale!.status == SaleStatus.refunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction has already been fully refunded.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReturnDialog(sale: _sale!, salesRepo: widget.salesRepo),
    );

    if (result == true) {
      _loadSale();
    }
  }

  void _printReceipt() {
    if (_sale == null) return;
    showDialog(
      context: context,
      builder: (_) => ReceiptDialog(sale: _sale!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.transactions,
      title: _sale == null
          ? 'Transaction Details'
          : 'Receipt #${_sale!.id.length > 8 ? _sale!.id.substring(_sale!.id.length - 8) : _sale!.id}',
      actions: [
        if (_sale != null) ...[
          CustomButton(
            label: 'Print Receipt',
            icon: Icons.print_outlined,
            variant: CustomButtonVariant.outline,
            height: 38,
            onPressed: _printReceipt,
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!_isFullyReturned && _sale!.status != SaleStatus.refunded)
            CustomButton(
              label: 'Return / Refund',
              icon: Icons.keyboard_return_rounded,
              variant: CustomButtonVariant.danger,
              height: 38,
              onPressed: _showReturnDialog,
            ),
        ],
      ],
      body: _isLoading
          ? const LoadingView(message: 'Loading transaction...')
          : _sale == null
              ? EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transaction Not Found',
                  description:
                      'The requested transaction (${widget.transactionId}) could not be retrieved.',
                  actionLabel: 'Back to Transactions',
                  onAction: () => Navigator.maybePop(context),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final sale = _sale!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Breadcrumb & Quick Info
              _buildTopMetaBar(sale, isDark),
              const SizedBox(height: AppSpacing.lg),

              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Item List & Returns (60%)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildItemsCard(sale, isDark),
                          if (sale.returns.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _buildReturnsHistoryCard(sale, isDark),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Summary & Actions Side Panel (40%)
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildFinancialSummaryCard(sale, isDark),
                          const SizedBox(height: AppSpacing.md),
                          _buildCustomerCard(sale, isDark),
                          const SizedBox(height: AppSpacing.md),
                          _buildActionsCard(sale, isDark),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                // Mobile stacked layout
                _buildFinancialSummaryCard(sale, isDark),
                const SizedBox(height: AppSpacing.md),
                _buildCustomerCard(sale, isDark),
                const SizedBox(height: AppSpacing.md),
                _buildItemsCard(sale, isDark),
                if (sale.returns.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildReturnsHistoryCard(sale, isDark),
                ],
                const SizedBox(height: AppSpacing.md),
                _buildActionsCard(sale, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopMetaBar(SaleTransaction sale, bool isDark) {
    final dateStr =
        '${sale.timestamp.year}-${sale.timestamp.month.toString().padLeft(2, '0')}-${sale.timestamp.day.toString().padLeft(2, '0')} ${sale.timestamp.hour.toString().padLeft(2, '0')}:${sale.timestamp.minute.toString().padLeft(2, '0')}';

    return CustomCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TRX-${sale.id.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildSaleStatusBadge(sale.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Placed on $dateStr • Terminal #01',
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
        ],
      ),
    );
  }

  Widget _buildSaleStatusBadge(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed:
        return const StatusBadge(
          label: 'COMPLETED',
          type: StatusType.success,
        );
      case SaleStatus.refunded:
        return const StatusBadge(
          label: 'REFUNDED',
          type: StatusType.danger,
        );
      case SaleStatus.cancelled:
        return const StatusBadge(
          label: 'CANCELLED',
          type: StatusType.neutral,
        );
    }
  }

  Widget _buildItemsCard(SaleTransaction sale, bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Purchased Items (${sale.items.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Qty: ${sale.items.fold(0, (sum, i) => sum + i.quantity)} total',
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
          const Divider(height: 1),

          // Item Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sale.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = sale.items[index];
              final hasReturn = item.returnedQuantity > 0;

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceMuted
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.normal),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'SKU: ${item.productSku.isEmpty ? 'N/A' : item.productSku}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•  \$${item.unitPrice.toStringAsFixed(2)} each',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (hasReturn) ...[
                            const SizedBox(height: 4),
                            StatusBadge(
                              label: 'Returned: ${item.returnedQuantity}',
                              type: StatusType.danger,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'x${item.quantity}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(SaleTransaction sale, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment & Totals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRow('Subtotal', '\$${sale.subtotal.toStringAsFixed(2)}', isDark),
          if (sale.discount > 0)
            _buildRow(
              'Discount',
              '-\$${sale.discount.toStringAsFixed(2)}',
              isDark,
              valueColor: AppColors.danger,
            ),
          if (sale.tax > 0)
            _buildRow('Tax (GST/VAT)', '\$${sale.tax.toStringAsFixed(2)}', isDark),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${sale.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceMuted
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.normal),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sale.paymentMethod == PaymentMethod.cash
                              ? Icons.payments_outlined
                              : Icons.credit_card,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Payment: ${sale.paymentMethod.name.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${sale.amountReceived.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (sale.change > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Given',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${sale.change.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(SaleTransaction sale, bool isDark) {
    final hasCustomer = sale.customerName != null && sale.customerName!.isNotEmpty;

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasCustomer
                  ? AppColors.primarySoft
                  : (isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCustomer ? Icons.person : Icons.person_outline,
              size: 20,
              color: hasCustomer ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCustomer ? sale.customerName! : 'Walk-in Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hasCustomer
                      ? 'ID: ${sale.customerId ?? 'Registered'}'
                      : 'No profile attached',
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
        ],
      ),
    );
  }

  Widget _buildReturnsHistoryCard(SaleTransaction sale, bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_return_outlined,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Returns & Refunds (${sale.returns.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sale.returns.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = sale.returns[index];
              if (r is! ReturnTransaction) {
                return ListTile(
                  title: Text('Return #${index + 1}'),
                  subtitle: const Text('Refund recorded'),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RET-${r.id.toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '-\$${r.totalRefund.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge(
                          label: r.reason.name.toUpperCase(),
                          type: StatusType.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'via ${r.refundMethod.name.toUpperCase()} • ${r.timestamp.toLocal().toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (r.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...r.items.map((ri) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '• ${ri.quantity}x ${ri.productName}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '\$${ri.refundAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(SaleTransaction sale, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            label: 'Print Thermal Receipt',
            icon: Icons.print_outlined,
            variant: CustomButtonVariant.outline,
            fullWidth: true,
            height: 44,
            onPressed: _printReceipt,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!_isFullyReturned && sale.status != SaleStatus.refunded)
            CustomButton(
              label: 'Issue Return / Refund',
              icon: Icons.keyboard_return_rounded,
              variant: CustomButtonVariant.danger,
              fullWidth: true,
              height: 44,
              onPressed: _showReturnDialog,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.normal),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'All items returned / refunded',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
