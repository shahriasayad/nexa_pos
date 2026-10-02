import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';

void main() {
  group('MockSalesRepository filters', () {
    late MockSalesRepository repo;

    setUp(() async {
      repo = MockSalesRepository();
      // Add mock data
      await repo.createSale(SaleTransaction(
        id: '1', timestamp: DateTime(2023, 1, 1, 10), items: [],
        subtotal: 10, discount: 0, tax: 0, total: 10,
        paymentMethod: PaymentMethod.cash, amountReceived: 10, change: 0, status: SaleStatus.completed,
      ));
      await repo.createSale(SaleTransaction(
        id: '2', timestamp: DateTime(2023, 1, 2, 10), items: [],
        subtotal: 20, discount: 0, tax: 0, total: 20,
        paymentMethod: PaymentMethod.card, amountReceived: 20, change: 0, status: SaleStatus.completed,
      ));
      await repo.createSale(SaleTransaction(
        id: '3', timestamp: DateTime(2023, 1, 3, 10), items: [],
        subtotal: 30, discount: 0, tax: 0, total: 30,
        paymentMethod: PaymentMethod.cash, amountReceived: 30, change: 0, status: SaleStatus.refunded,
      ));
    });

    test('getSales without filters returns all', () async {
      final sales = await repo.getSales();
      expect(sales.length, 3);
    });

    test('getSales filters by payment method', () async {
      final sales = await repo.getSales(paymentMethod: PaymentMethod.card);
      expect(sales.length, 1);
      expect(sales.first.id, '2');
    });

    test('getSales filters by date range', () async {
      final sales = await repo.getSales(
        startDate: DateTime(2023, 1, 2, 0),
        endDate: DateTime(2023, 1, 2, 23, 59),
      );
      expect(sales.length, 1);
      expect(sales.first.id, '2');
    });

    test('getSales filters by status', () async {
      final sales = await repo.getSales(status: SaleStatus.refunded);
      expect(sales.length, 1);
      expect(sales.first.id, '3');
    });
  });
}
