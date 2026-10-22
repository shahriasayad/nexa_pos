import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/auth/auth_provider.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/features/customers/domain/models/customer.dart';
import 'package:nexa_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nexa_pos/features/pos/domain/models/sale_transaction.dart';
import 'package:nexa_pos/features/pos/presentation/controllers/pos_controller.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/features/products/presentation/controllers/product_controller.dart';
import 'package:nexa_pos/features/purchases/domain/models/purchase_order.dart';
import 'package:nexa_pos/features/purchases/presentation/controllers/purchase_controller.dart';
import 'package:nexa_pos/features/returns/presentation/controllers/return_controller.dart';

void main() {
  group('End-to-End Business Workflows & Data Integrity', () {
    setUp(() {
      AppRepositories.reset();
      AuthProvider.instance.testLoginAdmin();
    });

    test('POS Sale -> Inventory deduction -> Customer update -> Dashboard metrics', () async {
      final repos = AppRepositories.instance;

      // 1. Initial State Check
      final initialProducts = await repos.productRepo.getProducts();
      final targetProduct = initialProducts.first;
      final initialStock = targetProduct.stockQuantity;

      final customers = await repos.customerRepo.getCustomers();
      final targetCustomer = customers.first;
      final initialSpending = targetCustomer.totalSpending;
      final initialPoints = targetCustomer.loyaltyPoints;

      // 2. Perform POS Checkout
      final posController = PosController(
        productRepo: repos.productRepo,
        inventoryRepo: repos.inventoryRepo,
        salesRepo: repos.salesRepo,
        customerRepo: repos.customerRepo,
      );

      await posController.searchProducts(null);
      posController.setCustomer(targetCustomer);
      posController.addToCart(targetProduct);
      posController.setDiscount(5.0); // $5 discount
      posController.setTax(2.0); // $2 tax

      final expectedTotal = (targetProduct.sellingPrice * 1) - 5.0 + 2.0;
      expect(posController.grandTotal, equals(expectedTotal));

      final checkoutSuccess = await posController.checkout(PaymentMethod.cash, expectedTotal);
      expect(checkoutSuccess, isTrue);

      final completedSale = posController.lastCompletedSale;
      expect(completedSale, isNotNull);
      expect(completedSale!.customerId, equals(targetCustomer.id));
      expect(completedSale.discount, equals(5.0));
      expect(completedSale.tax, equals(2.0));
      expect(completedSale.total, equals(expectedTotal));

      // 3. Verify Inventory Stock Deducted
      final updatedProduct = await repos.productRepo.getProductById(targetProduct.id);
      expect(updatedProduct!.stockQuantity, equals(initialStock - 1));

      // 4. Verify Customer Updated
      final updatedCustomer = await repos.customerRepo.getCustomerById(targetCustomer.id);
      expect(updatedCustomer!.totalSpending, equals(initialSpending + expectedTotal));
      expect(updatedCustomer.loyaltyPoints, equals(initialPoints + expectedTotal.toInt()));

      // 5. Verify Dashboard Metrics Unified
      final dashboardMetrics = await repos.dashboardRepo.getMetrics(DashboardFilter.today);
      expect(dashboardMetrics.ordersCount, greaterThanOrEqualTo(1));
      expect(dashboardMetrics.revenue, greaterThanOrEqualTo(expectedTotal));

      final recentTrx = await repos.dashboardRepo.getRecentTransactions(5);
      expect(recentTrx.any((t) => t.id == completedSale.id), isTrue);
    });

    test('Return Transaction -> Stock restoration -> Customer spending decrement -> Dashboard net update', () async {
      final repos = AppRepositories.instance;

      // 1. Create a sale first
      final posController = PosController(
        productRepo: repos.productRepo,
        inventoryRepo: repos.inventoryRepo,
        salesRepo: repos.salesRepo,
        customerRepo: repos.customerRepo,
      );

      final initialProducts = await repos.productRepo.getProducts();
      final product = initialProducts.first;
      final customers = await repos.customerRepo.getCustomers();
      final customer = customers.first;

      posController.setCustomer(customer);
      posController.addToCart(product);
      final saleTotal = posController.grandTotal;
      await posController.checkout(PaymentMethod.card, saleTotal);

      final sale = posController.lastCompletedSale!;
      final stockAfterSale = (await repos.productRepo.getProductById(product.id))!.stockQuantity;
      final spendingAfterSale = (await repos.customerRepo.getCustomerById(customer.id))!.totalSpending;

      // 2. Process Return via ReturnController
      final returnController = ReturnController(
        salesRepo: repos.salesRepo,
        inventoryRepo: repos.inventoryRepo,
        productRepo: repos.productRepo,
        customerRepo: repos.customerRepo,
      );

      returnController.setReturnQuantity(product.id, 1, 1);
      final refundAmt = returnController.calculateRefundAmount(sale);
      expect(refundAmt, equals(product.sellingPrice));

      final returnSuccess = await returnController.submitReturn(sale);
      expect(returnSuccess, isTrue);

      // 3. Verify Stock Restored
      final stockAfterReturn = (await repos.productRepo.getProductById(product.id))!.stockQuantity;
      expect(stockAfterReturn, equals(stockAfterSale + 1));

      // 4. Verify Customer Total Spending Deducted
      final spendingAfterReturn = (await repos.customerRepo.getCustomerById(customer.id))!.totalSpending;
      expect(spendingAfterReturn, closeTo(spendingAfterSale - product.sellingPrice, 0.01));

      // 5. Verify Dashboard reflects refunds
      final metrics = await repos.dashboardRepo.getMetrics(DashboardFilter.today);
      expect(metrics.refunds, greaterThanOrEqualTo(product.sellingPrice));
    });

    test('Purchase Receipt -> Product stock increment & inventory movement logging', () async {
      final repos = AppRepositories.instance;

      final products = await repos.productRepo.getProducts();
      final product = products.first;
      final initialStock = product.stockQuantity;

      final purchaseController = PurchaseController(
        purchaseRepo: repos.purchaseRepo,
        inventoryRepo: repos.inventoryRepo,
        productRepo: repos.productRepo,
      );

      final po = PurchaseOrder(
        id: 'PO-TEST-001',
        supplierId: 'sup-1',
        supplierName: 'Test Vendor',
        status: PurchaseStatus.ordered,
        items: [
          PurchaseItem(
            productId: product.id,
            productName: product.name,
            quantity: 10,
            unitCost: product.purchasePrice,
          ),
        ],
        totalAmount: product.purchasePrice * 10,
        orderDate: DateTime.now(),
      );

      await purchaseController.savePurchase(po);

      // Receive the purchase order
      final receiveSuccess = await purchaseController.receivePurchase(
        po,
        [
          PurchaseItem(
            productId: product.id,
            productName: product.name,
            quantity: 10,
            receivedQuantity: 10,
            unitCost: product.purchasePrice,
          ),
        ],
      );

      expect(receiveSuccess, isTrue);

      // Verify product stock increased
      final updatedProduct = await repos.productRepo.getProductById(product.id);
      expect(updatedProduct!.stockQuantity, equals(initialStock + 10));

      // Verify inventory movements include the purchase
      final movements = await repos.inventoryRepo.getMovementsForProduct(product.id);
      expect(movements.any((m) => m.referenceId == po.id), isTrue);
    });

    test('ProductController creates product with empty ID without error', () async {
      final repos = AppRepositories.instance;
      final controller = ProductController(
        productRepo: repos.productRepo,
        categoryRepo: repos.categoryRepo,
      );

      final newProduct = Product(
        id: '', // Empty ID as when user clicks 'Create Product'
        name: 'Brand New Gizmo',
        sku: 'GIZMO-999',
        sellingPrice: 49.99,
        purchasePrice: 20.00,
        stockQuantity: 15,
        minimumStock: 5,
        categoryId: 'cat-1',
        barcode: '1234567890999',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = await controller.saveProduct(newProduct);
      expect(saved, isTrue);
      expect(controller.errorMessage, isNull);

      final found = controller.products.any((p) => p.sku == 'GIZMO-999');
      expect(found, isTrue);
    });

    test('Customer CRUD: create, update, delete operations', () async {
      final repos = AppRepositories.instance;
      final repo = repos.customerRepo;

      final customer = Customer(
        id: 'CUST-TEST-123',
        name: 'Alice Wonder',
        phone: '+1 555-0100',
        email: 'alice@example.com',
        createdAt: DateTime.now(),
      );

      await repo.addCustomer(customer);
      final retrieved = await repo.getCustomerById('CUST-TEST-123');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Alice Wonder');

      final updated = customer.copyWith(name: 'Alice In Wonderland', loyaltyPoints: 50);
      await repo.updateCustomer(updated);
      final retrieved2 = await repo.getCustomerById('CUST-TEST-123');
      expect(retrieved2!.name, 'Alice In Wonderland');
      expect(retrieved2.loyaltyPoints, 50);

      await repo.deleteCustomer('CUST-TEST-123');
      final retrieved3 = await repo.getCustomerById('CUST-TEST-123');
      expect(retrieved3, isNull);
    });
  });
}
