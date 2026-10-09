import 'package:flutter/material.dart';

import '../../../../core/state/view_state.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/sales_repository.dart';

class TransactionHistoryController extends ChangeNotifier {
  final SalesRepository salesRepo;

  TransactionHistoryController({required this.salesRepo});

  ViewState state = ViewState.initial;
  List<SaleTransaction> transactions = [];

  String? searchId;
  DateTime? startDate;
  DateTime? endDate;
  PaymentMethod? paymentMethod;
  SaleStatus? status;

  Future<void> loadTransactions() async {
    state = ViewState.loading;
    notifyListeners();

    try {
      transactions = await salesRepo.getSales(
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
        status: status,
      );

      if (searchId != null && searchId!.isNotEmpty) {
        transactions = transactions
            .where((t) => t.id.contains(searchId!))
            .toList();
      }

      state = transactions.isEmpty ? ViewState.empty : ViewState.success;
    } catch (e) {
      state = ViewState.error;
    }
    notifyListeners();
  }

  void setFilters({
    String? search,
    DateTime? start,
    DateTime? end,
    PaymentMethod? method,
    SaleStatus? status,
  }) {
    searchId = search;
    startDate = start;
    endDate = end;
    paymentMethod = method;
    this.status = status;
    loadTransactions();
  }

  void clearFilters() {
    searchId = null;
    startDate = null;
    endDate = null;
    paymentMethod = null;
    status = null;
    loadTransactions();
  }
}
