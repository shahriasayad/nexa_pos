import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/features/dashboard/data/repositories/mock_dashboard_repository.dart';
import 'package:nexa_pos/features/pos/data/repositories/mock_sales_repository.dart';
import 'package:nexa_pos/features/products/data/repositories/mock_product_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/returns/domain/models/return_transaction.dart';
import 'package:nexa_pos/features/dashboard/domain/repositories/dashboard_repository.dart';

void main() {
  group('MockDashboardRepository integration with returns', () {
    late MockSalesRepository salesRepo;
    late MockProductRepository productRepo;
    late MockDashboardRepository dashboardRepo;

    setUp(() async {
      salesRepo = MockSalesRepository();
      productRepo = MockProductRepository();
      dashboardRepo = MockDashboardRepository(
        salesRepo: salesRepo,
        productRepo: productRepo,
      );

      final sale = SaleTransaction(
        id: 's1', timestamp: DateTime.now(),
        items: [SaleItem(productId: '1', productName: 'P1', productSku: 'sku', unitPrice: 50, quantity: 2, lineTotal: 100)],
        subtotal: 100, discount: 0, tax: 0, total: 100,
        paymentMethod: PaymentMethod.cash, amountReceived: 100, change: 0, status: SaleStatus.completed,
      );
      await salesRepo.createSale(sale);
      
      final returnTx = ReturnTransaction(
        id: 'r1',
        originalTransactionId: 's1',
        timestamp: DateTime.now(),
        items: [ReturnItem(productId: '1', productName: 'P1', unitPrice: 50, quantity: 1, refundAmount: 50)],
        totalRefund: 50,
        refundMethod: PaymentMethod.cash,
        reason: ReturnReason.changedMind,
      );
      await salesRepo.returnItems('s1', returnTx);
    });

    test('getMetrics accounts for refunds in net revenue', () async {
      final metrics = await dashboardRepo.getMetrics(DashboardFilter.today);
      expect(metrics.revenue, 50.0); // 100 - 50
      expect(metrics.refunds, 50.0);
    });
  });
}
