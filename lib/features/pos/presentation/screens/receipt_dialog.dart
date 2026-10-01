import 'package:flutter/material.dart';
import '../../domain/models/sale_transaction.dart';

class ReceiptDialog extends StatelessWidget {
  final SaleTransaction sale;

  const ReceiptDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sale Complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${sale.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Time: ${sale.timestamp.toString().split('.')[0]}'),
            const Divider(),
            ...sale.items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${i.quantity}x ${i.productName}'),
                  Text('\$${i.lineTotal.toStringAsFixed(2)}'),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid (${sale.paymentMethod.name}):'),
                Text('\$${sale.amountReceived.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change:'),
                Text('\$${sale.change.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
