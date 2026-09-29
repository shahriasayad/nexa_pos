import 'package:flutter/material.dart';
import '../../domain/models/transaction_summary.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<TransactionSummary> transactions;

  const RecentTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No recent transactions')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trx = transactions[index];
                return ListTile(
                  title: Text(trx.id),
                  subtitle: Text(
                    '${trx.date.hour}:${trx.date.minute.toString().padLeft(2, '0')} - ${trx.status}',
                  ),
                  trailing: Text(
                    '\$${trx.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: trx.status == 'Refunded' ? Colors.red : null,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
