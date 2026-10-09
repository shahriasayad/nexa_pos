import 'package:flutter/material.dart';

import '../../../../features/pos/domain/models/sale_transaction.dart';
import '../../../../features/pos/data/repositories/mock_sales_repository.dart';
import '../../../../features/returns/presentation/screens/return_dialog.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

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
    setState(() {
      _sale = sale;
      _isLoading = false;
    });
  }

  void _showReturnDialog() async {
    if (_sale == null) return;

    // Check if fully returned
    bool fullyReturned = true;
    for (var item in _sale!.items) {
      if (item.returnedQuantity < item.quantity) {
        fullyReturned = false;
        break;
      }
    }

    if (fullyReturned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction is fully returned.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sale == null
          ? const Center(child: Text('Transaction not found'))
          : _buildDetails(),
    );
  }

  Widget _buildDetails() {
    final sale = _sale!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${sale.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text('Date: ${sale.timestamp.toString().split('.')[0]}'),
          Text('Status: ${sale.status.name.toUpperCase()}'),
          const Divider(),
          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...sale.items.map((item) {
            return ListTile(
              title: Text(item.productName),
              subtitle: Text(
                '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.returnedQuantity > 0)
                    Text(
                      'Returned: ${item.returnedQuantity}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '\$${sale.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid via ${sale.paymentMethod.name}:'),
              Text('\$${sale.amountReceived.toStringAsFixed(2)}'),
            ],
          ),
          if (sale.returns.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Returns:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...sale.returns.map((r) {
              return ListTile(
                leading: const Icon(
                  Icons.assignment_return,
                  color: AppColors.danger,
                ),
                title: Text('Return: ${r.id}'),
                subtitle: Text('Refund: \$${r.totalRefund.toStringAsFixed(2)}'),
              );
            }),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.keyboard_return),
              label: const Text('Issue Return / Refund'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
              ),
              onPressed: sale.status == SaleStatus.refunded
                  ? null
                  : _showReturnDialog,
            ),
          ),
        ],
      ),
    );
  }
}
