import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../domain/models/sale_transaction.dart';
import '../../data/repositories/mock_sales_repository.dart';
import '../controllers/transaction_history_controller.dart';
import 'receipt_dialog.dart';
import '../../../../core/layout/app_drawer.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late TransactionHistoryController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TransactionHistoryController(salesRepo: MockSalesRepository());
    _controller.loadTransactions();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showReceipt(SaleTransaction sale) {
    showDialog(context: context, builder: (_) => ReceiptDialog(sale: sale));
  }

  void _openFilterDialog() async {
    DateTime? start = _controller.startDate;
    DateTime? end = _controller.endDate;
    PaymentMethod? method = _controller.paymentMethod;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Transactions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PaymentMethod?>(
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    value: method,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))),
                    ],
                    onChanged: (v) => setState(() => method = v),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: (start != null && end != null) 
                          ? DateTimeRange(start: start!, end: end!) : null,
                      );
                      if (picked != null) {
                        setState(() {
                          start = picked.start;
                          end = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
                        });
                      }
                    },
                    child: Text(start != null && end != null 
                        ? '${start!.toString().split(' ')[0]} - ${end!.toString().split(' ')[0]}'
                        : 'Select Date Range'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply')),
            ],
          );
        });
      }
    );

    if (result == true) {
      _controller.setFilters(
        search: _searchController.text,
        start: start,
        end: end,
        method: method,
        status: _controller.status,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.loadTransactions,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Transaction ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearFilters();
                  },
                ),
              ),
              onSubmitted: (v) => _controller.setFilters(search: v),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const LoadingView(message: 'Loading transactions...');
      case ViewState.error:
        return ErrorView(message: 'Failed to load', onRetry: _controller.loadTransactions);
      case ViewState.empty:
        return const EmptyStateView(message: 'No transactions found.', icon: Icons.receipt_long);
      case ViewState.success:
        return ListView.builder(
          itemCount: _controller.transactions.length,
          itemBuilder: (context, index) {
            final sale = _controller.transactions[index];
            return ListTile(
              leading: const Icon(Icons.receipt),
              title: Text('ID: ${sale.id}'),
              subtitle: Text('${sale.timestamp.toString().split('.')[0]} | ${sale.paymentMethod.name.toUpperCase()}'),
              trailing: Text('\$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () => _showReceipt(sale),
            );
          },
        );
    }
    return const SizedBox.shrink();
  }
}
