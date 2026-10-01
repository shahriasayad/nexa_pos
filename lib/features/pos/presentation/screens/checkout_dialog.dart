import 'package:flutter/material.dart';
import '../../domain/models/sale_transaction.dart';
import '../controllers/pos_controller.dart';

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
    _amountController = TextEditingController(text: widget.controller.grandTotal.toStringAsFixed(2));
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

  @override
  Widget build(BuildContext context) {
    final total = widget.controller.grandTotal;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final change = amount > total ? amount - total : 0.0;

    return AlertDialog(
      title: const Text('Checkout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Due: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              decoration: const InputDecoration(labelText: 'Payment Method'),
              value: _method,
              items: PaymentMethod.values.map((m) => DropdownMenuItem(
                value: m,
                child: Text(m.name.toUpperCase()),
              )).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            if (_method == PaymentMethod.cash) ...[
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount Received'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text('Change: \$${change.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
            ],
            if (widget.controller.isProcessingCheckout)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.controller.isProcessingCheckout ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: widget.controller.isProcessingCheckout ? null : _confirm, child: const Text('Confirm Sale')),
      ],
    );
  }
}
