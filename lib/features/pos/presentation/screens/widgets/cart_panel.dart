import 'package:flutter/material.dart';

import '../../controllers/pos_controller.dart';
import '../../../../../shared/widgets/custom_button.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              controller.selectedCustomer?.name ?? 'Walk-in Customer',
            ),
            subtitle: Text(
              controller.selectedCustomer != null
                  ? 'Customer selected'
                  : 'No customer attached',
            ),
            trailing: TextButton(
              onPressed: onShowCustomerSelection,
              child: const Text('Change'),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: controller.cart.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView.builder(
                  itemCount: controller.cart.length,
                  itemBuilder: (context, index) {
                    final item = controller.cart[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        '\$${item.product.sellingPrice.toStringAsFixed(2)} x ${item.quantity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => controller.updateQuantity(
                              item.product,
                              item.quantity - 1,
                            ),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => controller.addToCart(item.product),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.danger,
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
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${controller.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${controller.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Clear',
                      variant: CustomButtonVariant.outline,
                      onPressed: controller.cart.isEmpty
                          ? null
                          : controller.clearCart,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      label: 'Checkout',
                      variant: CustomButtonVariant.primary,
                      onPressed: controller.cart.isEmpty
                          ? null
                          : onShowCheckout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
