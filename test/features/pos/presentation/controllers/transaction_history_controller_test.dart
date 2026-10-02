import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/transaction_history_controller.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/core/state/view_state.dart';

void main() {
  group('TransactionHistoryController', () {
    late TransactionHistoryController controller;
    late MockSalesRepository repo;

    setUp(() async {
      repo = MockSalesRepository();
      controller = TransactionHistoryController(salesRepo: repo);

      await repo.createSale(
        SaleTransaction(
          id: 'txn1',
          timestamp: DateTime(2023, 1, 1),
          items: [],
          subtotal: 10,
          discount: 0,
          tax: 0,
          total: 10,
          paymentMethod: PaymentMethod.cash,
          amountReceived: 10,
          change: 0,
          status: SaleStatus.completed,
        ),
      );
      await repo.createSale(
        SaleTransaction(
          id: 'txn2',
          timestamp: DateTime(2023, 1, 2),
          items: [],
          subtotal: 20,
          discount: 0,
          tax: 0,
          total: 20,
          paymentMethod: PaymentMethod.card,
          amountReceived: 20,
          change: 0,
          status: SaleStatus.completed,
        ),
      );
    });

    test('loadTransactions loads all initially', () async {
      await controller.loadTransactions();
      expect(controller.state, ViewState.success);
      expect(controller.transactions.length, 2);
    });

    test('setFilters filters by id string', () async {
      controller.setFilters(search: 'txn2');
      // setFilters calls loadTransactions, but it's async so we wait
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.transactions.length, 1);
      expect(controller.transactions.first.id, 'txn2');
    });

    test('clearFilters resets to all', () async {
      controller.setFilters(search: 'txn2');
      await Future.delayed(const Duration(milliseconds: 300));
      controller.clearFilters();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.transactions.length, 2);
    });
  });
}
