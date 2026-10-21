import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/purchases/data/repositories/mock_purchase_repository.dart';
import 'package:nexa_pos/features/purchases/domain/models/purchase_order.dart';
import 'package:nexa_pos/features/purchases/presentation/controllers/purchase_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class ReceivePurchaseScreen extends StatefulWidget {
  final PurchaseOrder purchase;

  const ReceivePurchaseScreen({super.key, required this.purchase});

  @override
  State<ReceivePurchaseScreen> createState() => _ReceivePurchaseScreenState();
}

class _ReceivePurchaseScreenState extends State<ReceivePurchaseScreen> {
  late PurchaseController _controller;
  late List<PurchaseItem> _items;

  @override
  void initState() {
    super.initState();
    _controller = PurchaseController(
      purchaseRepo: MockPurchaseRepository(),
      inventoryRepo: MockInventoryRepository(),
      productRepo: MockProductRepository(),
    );
    // Initialize received quantity to the ordered quantity by default (assuming full receipt)
    _items = widget.purchase.items
        .map((item) => item.copyWith(receivedQuantity: item.quantity))
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateReceivedQuantity(int index, int qty) {
    setState(() {
      _items[index] = _items[index].copyWith(receivedQuantity: qty < 0 ? 0 : qty);
    });
  }

  void _receiveAll() {
    setState(() {
      _items = widget.purchase.items
          .map((item) => item.copyWith(receivedQuantity: item.quantity))
          .toList();
    });
  }

  void _receive() async {
    final success = await _controller.receivePurchase(widget.purchase, _items);
    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Failed to receive purchase',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalOrdered =
        widget.purchase.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final totalReceiving =
        _items.fold<int>(0, (sum, i) => sum + i.receivedQuantity);

    return AppShell(
      currentRoute: AppRoutes.purchases,
      title: 'Receive PO-${widget.purchase.id}',
      actions: [
        CustomButton(
          label: 'Cancel',
          variant: CustomButtonVariant.outline,
          height: 38,
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return CustomButton(
              label: 'Confirm Receipt & Restock',
              icon: Icons.check,
              variant: CustomButtonVariant.primary,
              isLoading: _controller.state == ViewState.loading,
              height: 38,
              onPressed: _controller.state == ViewState.loading ? null : _receive,
            );
          },
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPageHeader(
                  title: 'Receive Purchase Order',
                  subtitle:
                      'Inspect incoming delivery and confirm received counts to increase on-hand inventory.',
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // PO Context Card
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.normal),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          size: 24,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PO-${widget.purchase.id}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Supplier: ${widget.purchase.supplierName} • Ordered: ${widget.purchase.orderDate.toString().split(' ')[0]}',
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
                      TextButton.icon(
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Receive All'),
                        onPressed: _receiveAll,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Intake Checklist
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Line Items Verification',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Receiving $totalReceiving of $totalOrdered items',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final orderedQty =
                              widget.purchase.items[index].quantity;
                          final isFull = item.receivedQuantity == orderedQty;

                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
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
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Ordered: $orderedQty units',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(
                                            label: isFull
                                                ? 'FULL RECEIPT'
                                                : '${item.receivedQuantity}/$orderedQty',
                                            type: isFull
                                                ? StatusType.success
                                                : StatusType.warning,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Stepper
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceMuted
                                        : AppColors.surfaceMuted,
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
                                        onPressed: item.receivedQuantity > 0
                                            ? () => _updateReceivedQuantity(
                                                index, item.receivedQuantity - 1)
                                            : null,
                                      ),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${item.receivedQuantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _updateReceivedQuantity(
                                            index, item.receivedQuantity + 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Bottom Confirmation Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      label: 'Cancel',
                      variant: CustomButtonVariant.outline,
                      height: 44,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        return CustomButton(
                          label: 'Confirm Receipt & Update Inventory',
                          icon: Icons.check,
                          variant: CustomButtonVariant.primary,
                          isLoading: _controller.state == ViewState.loading,
                          height: 44,
                          onPressed: _controller.state == ViewState.loading
                              ? null
                              : _receive,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
