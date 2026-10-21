import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';

class ReceiptDialog extends StatelessWidget {
  final SaleTransaction sale;

  const ReceiptDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateFormatted =
        '${sale.timestamp.year}-${sale.timestamp.month.toString().padLeft(2, '0')}-${sale.timestamp.day.toString().padLeft(2, '0')} ${sale.timestamp.hour.toString().padLeft(2, '0')}:${sale.timestamp.minute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success checkmark header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primaryStrong,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Sale Completed!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Transaction #TRX-${sale.id.length > 8 ? sale.id.substring(sale.id.length - 8) : sale.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Receipt Paper Container
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.normal),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Store Details
                    const Center(
                      child: Text(
                        'NEXA POS RETAIL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Store #01 • Main Terminal\nDate: $dateFormatted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (sale.customerName != null) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Customer: ${sale.customerName}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildDottedLine(isDark),
                    const SizedBox(height: AppSpacing.sm),

                    // Items Table
                    ...sale.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantity}x ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '\$${item.lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppSpacing.sm),
                    _buildDottedLine(isDark),
                    const SizedBox(height: AppSpacing.sm),

                    // Totals
                    _buildSummaryRow(
                      'Subtotal',
                      '\$${sale.subtotal.toStringAsFixed(2)}',
                      isDark,
                    ),
                    if (sale.discount > 0)
                      _buildSummaryRow(
                        'Discount',
                        '-\$${sale.discount.toStringAsFixed(2)}',
                        isDark,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '\$${sale.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                      'Paid (${sale.paymentMethod.name.toUpperCase()})',
                      '\$${sale.amountReceived.toStringAsFixed(2)}',
                      isDark,
                    ),
                    _buildSummaryRow(
                      'Change Due',
                      '\$${sale.change.toStringAsFixed(2)}',
                      isDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Print',
                      icon: Icons.print_outlined,
                      variant: CustomButtonVariant.outline,
                      height: 42,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Receipt sent to default printer'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      label: 'New Sale',
                      icon: Icons.add,
                      variant: CustomButtonVariant.primary,
                      height: 42,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDottedLine(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
