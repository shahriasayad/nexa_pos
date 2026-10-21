import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/pos_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';

class CartPanel extends StatelessWidget {
  final PosController controller;
  final VoidCallback onShowCustomerSelection;
  final VoidCallback onShowCheckout;

  const CartPanel({
    super.key,
    required this.controller,
    required this.onShowCustomerSelection,
    required this.onShowCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customer = controller.selectedCustomer;

    final totalItemsCount =
        controller.cart.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header & Customer Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: customer != null
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                  child: Icon(
                    customer != null ? Icons.person : Icons.person_outline,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer?.name ?? 'Walk-in Customer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        customer?.phone ?? 'Standard Retail Sale',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onShowCustomerSelection,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    customer != null ? 'Change' : '+ Add',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Cart Subheader with Item count & Clear button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT CART ($totalItemsCount)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                if (controller.cart.isNotEmpty)
                  InkWell(
                    onTap: controller.clearCart,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),

          // Cart Items List
          Expanded(
            child: controller.cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.darkSurfaceMuted
                                  : AppColors.surfaceMuted,
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 36,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Cart is Empty',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select products from the catalog\nto start a transaction',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: controller.cart.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$${item.product.sellingPrice.toStringAsFixed(2)} each',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Stepper [-] [qty] [+]
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => controller.updateQuantity(
                                      item.product,
                                      item.quantity - 1,
                                    ),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(5),
                                    ),
                                    child: const SizedBox(
                                      width: 28,
                                      height: 32,
                                      child: Icon(Icons.remove, size: 14),
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 26),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => controller.addToCart(item.product),
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(5),
                                    ),
                                    child: const SizedBox(
                                      width: 28,
                                      height: 32,
                                      child: Icon(Icons.add, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),

                            // Line total
                            SizedBox(
                              width: 60,
                              child: Text(
                                '\$${item.lineTotal.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            // Remove
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.danger,
                              ),
                              splashRadius: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () =>
                                  controller.removeFromCart(item.product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Financial Summary and Actions
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  offset: const Offset(0, -3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${controller.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Tax & Discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '-\$${controller.discount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Grand Total Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceMuted
                        : AppColors.primarySoft.withValues(alpha: 0.6),
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
                        'TOTAL DUE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                      Text(
                        '\$${controller.grandTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
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
                const SizedBox(height: AppSpacing.md),

                // Checkout Primary Action
                CustomButton(
                  label: 'Proceed to Checkout',
                  icon: Icons.payment,
                  variant: CustomButtonVariant.primary,
                  isFullWidth: true,
                  height: 46,
                  fontSize: 15,
                  onPressed: controller.cart.isEmpty ? null : onShowCheckout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
