import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/pos_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';

class CheckoutDialog extends StatefulWidget {
  final PosController controller;

  const CheckoutDialog({super.key, required this.controller});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.controller.grandTotal.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < widget.controller.grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient amount received.')),
      );
      return;
    }

    final success = await widget.controller.checkout(_method, amount);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _setAmount(double value) {
    setState(() {
      _amountController.text = value.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.controller.grandTotal;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final change = amount >= total ? amount - total : 0.0;
    final isUnderpaid = amount < total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Quick cash suggestions
    final quickCashOptions = <double>{
      total,
      (total / 10).ceil() * 10.0,
      (total / 20).ceil() * 20.0,
      (total / 50).ceil() * 50.0,
      100.0,
    }.where((v) => v >= total).toList()
      ..sort();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Complete Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Total Due Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceMuted : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.normal),
                  border: Border.all(
                    color: (isDark ? AppColors.darkSuccess : AppColors.primary)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYABLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.primaryStrong,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.darkSuccess
                            : AppColors.primaryStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Payment Method Grid
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _method == method;
                  IconData icon;
                  switch (method) {
                    case PaymentMethod.cash:
                      icon = Icons.payments_outlined;
                      break;
                    case PaymentMethod.card:
                      icon = Icons.credit_card_outlined;
                      break;
                    case PaymentMethod.other:
                      icon = Icons.account_balance_outlined;
                      break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _method = method;
                            if (method != PaymentMethod.cash) {
                              _amountController.text = total.toStringAsFixed(2);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(AppRadius.normal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkSurfaceMuted
                                    : AppColors.primarySoft)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppRadius.normal),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.darkSuccess
                                      : AppColors.primary)
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkSuccess
                                        : AppColors.primary)
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                method.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.darkSuccess
                                          : AppColors.primaryStrong)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Cash Tender Input & Suggestions
              if (_method == PaymentMethod.cash) ...[
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount Received *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Quick cash buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickCashOptions.take(4).map((val) {
                    final isExact = val == total;
                    return InkWell(
                      onTap: () => _setAmount(val),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceMuted
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isExact ? 'Exact (\$${val.toStringAsFixed(2)})' : '\$${val.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Change Output
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isUnderpaid
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.normal),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUnderpaid ? 'Short by:' : 'Change Return:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isUnderpaid
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                      Text(
                        isUnderpaid
                            ? '-\$${(total - amount).toStringAsFixed(2)}'
                            : '\$${change.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnderpaid
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Cancel',
                      variant: CustomButtonVariant.outline,
                      height: 44,
                      onPressed: widget.controller.isProcessingCheckout
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      label: widget.controller.isProcessingCheckout
                          ? 'Processing...'
                          : 'Confirm Sale',
                      variant: CustomButtonVariant.primary,
                      height: 44,
                      isLoading: widget.controller.isProcessingCheckout,
                      onPressed: isUnderpaid || widget.controller.isProcessingCheckout
                          ? null
                          : _confirm,
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
}
