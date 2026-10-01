import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../domain/models/sale_transaction.dart';
import '../../data/repositories/mock_sales_repository.dart';
import 'receipt_dialog.dart';
import '../../../../core/layout/app_drawer.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final MockSalesRepository _salesRepo = MockSalesRepository();
  List<SaleTransaction> _sales = [];
  ViewState _state = ViewState.initial;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _state = ViewState.loading);
    try {
      _sales = await _salesRepo.getSales();
      setState(() => _state = _sales.isEmpty ? ViewState.empty : ViewState.success);
    } catch (e) {
      setState(() => _state = ViewState.error);
    }
  }

  void _showReceipt(SaleTransaction sale) {
    showDialog(context: context, builder: (_) => ReceiptDialog(sale: sale));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ViewState.initial:
      case ViewState.loading:
        return const LoadingView(message: 'Loading transactions...');
      case ViewState.error:
        return ErrorView(message: 'Failed to load', onRetry: _loadSales);
      case ViewState.empty:
        return const EmptyStateView(message: 'No transactions found.', icon: Icons.receipt_long);
      case ViewState.success:
        return ListView.builder(
          itemCount: _sales.length,
          itemBuilder: (context, index) {
            final sale = _sales[index];
            return ListTile(
              leading: const Icon(Icons.receipt),
              title: Text('Transaction: ${sale.id}'),
              subtitle: Text('${sale.timestamp.toString().split('.')[0]} | ${sale.paymentMethod.name.toUpperCase()}'),
              trailing: Text('\$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () => _showReceipt(sale),
            );
          },
        );
    }
  }
}
