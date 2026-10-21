import 'package:flutter/material.dart';

import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/returns/domain/models/return_transaction.dart';
import 'package:nexa_pos/features/returns/presentation/controllers/return_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';

class ReturnDialog extends StatefulWidget {
  final SaleTransaction sale;
  final MockSalesRepository salesRepo;

  const ReturnDialog({
    super.key,
    required this.sale,
    required this.salesRepo,
  });

  @override
  State<ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<ReturnDialog> {
  late ReturnController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReturnController(
      salesRepo: widget.salesRepo,
      productRepo: MockProductRepository(),
      inventoryRepo: MockInventoryRepository(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatReason(ReturnReason reason) {
    switch (reason) {
      case ReturnReason.changedMind:
        return 'Customer Mind';
      case ReturnReason.damaged:
        return 'Damaged Item';
      case ReturnReason.wrongProduct:
        return 'Wrong Item';
      case ReturnReason.defective:
        return 'Defective';
      case ReturnReason.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final refundAmount = _controller.calculateRefundAmount(widget.sale);
            final totalItemsToReturn = _controller.returnQuantities.values
                .fold<int>(0, (sum, qty) => sum + qty);

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.normal),
                        ),
                        child: const Icon(
                          Icons.keyboard_return_rounded,
                          color: AppColors.danger,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Process Return & Refund',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sale #TRX-${widget.sale.id.toUpperCase()}',
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
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Error Message Banner
                  if (_controller.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _controller.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Scrollable Return Items & Options
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Item Selection
                          const Text(
                            'Select Items to Return',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          ...widget.sale.items.map((item) {
                            final maxReturnable =
                                item.quantity - item.returnedQuantity;
                            if (maxReturnable <= 0) {
                              return const SizedBox.shrink();
                            }

                            final selectedQty =
                                _controller.returnQuantities[item.productId] ?? 0;
                            final itemRefund = selectedQty * item.unitPrice;

                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: selectedQty > 0
                                    ? (isDark
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : AppColors.primarySoft.withValues(alpha: 0.5))
                                    : (isDark
                                        ? AppColors.darkSurfaceMuted
                                        : AppColors.surfaceMuted),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.normal),
                                border: Border.all(
                                  color: selectedQty > 0
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Available: $maxReturnable / ${item.quantity}  •  \$${item.unitPrice.toStringAsFixed(2)} each',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                        if (selectedQty > 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Refund subtotal: \$${itemRefund.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Quantity Stepper
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.normal,
                                      ),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 16),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: selectedQty > 0
                                              ? () => _controller
                                                  .setReturnQuantity(
                                                    item.productId,
                                                    selectedQty - 1,
                                                    maxReturnable,
                                                  )
                                              : null,
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$selectedQty',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 16),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: selectedQty < maxReturnable
                                              ? () => _controller
                                                  .setReturnQuantity(
                                                    item.productId,
                                                    selectedQty + 1,
                                                    maxReturnable,
                                                  )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  TextButton(
                                    onPressed: () => _controller.setReturnQuantity(
                                      item.productId,
                                      maxReturnable,
                                      maxReturnable,
                                    ),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      'All',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),

                          // Section 2: Reason & Refund Method
                          const Text(
                            'Return Reason',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<ReturnReason>(
                            initialValue: _controller.selectedReason,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.help_outline, size: 18),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: ReturnReason.values
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(_formatReason(r)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _controller.selectedReason = v;
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Refund Method',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<PaymentMethod>(
                            initialValue: _controller.refundMethod,
                            decoration: const InputDecoration(
                              prefixIcon:
                                  Icon(Icons.payment_outlined, size: 18),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: PaymentMethod.values
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p.name.toUpperCase(),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _controller.refundMethod = v;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Refund Calculation Summary Banner
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL REFUND DUE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalItemsToReturn item(s) selected',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${refundAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Dialog Actions
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Cancel',
                          variant: CustomButtonVariant.outline,
                          height: 42,
                          onPressed: _controller.state == ViewState.loading
                              ? null
                              : () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          label: _controller.state == ViewState.loading
                              ? 'Processing...'
                              : 'Confirm Return',
                          icon: Icons.check,
                          variant: CustomButtonVariant.danger,
                          isLoading: _controller.state == ViewState.loading,
                          height: 42,
                          onPressed: (totalItemsToReturn == 0 ||
                                  _controller.state == ViewState.loading)
                              ? null
                              : () async {
                                  final success =
                                      await _controller.submitReturn(widget.sale);
                                  if (success && context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
