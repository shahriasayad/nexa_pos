import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/data/repositories/mock_product_repository.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/data/repositories/mock_category_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/data/repositories/mock_inventory_repository.dart';
import '../../features/pos/domain/repositories/sales_repository.dart';
import '../../features/pos/data/repositories/mock_sales_repository.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/customers/data/repositories/mock_customer_repository.dart';
import '../../features/suppliers/domain/repositories/supplier_repository.dart';
import '../../features/suppliers/data/repositories/mock_supplier_repository.dart';
import '../../features/purchases/domain/repositories/purchase_repository.dart';
import '../../features/purchases/data/repositories/mock_purchase_repository.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/data/repositories/mock_expense_repository.dart';
import '../../features/employees/domain/repositories/employee_repository.dart';
import '../../features/employees/data/repositories/mock_employee_repository.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/repositories/mock_dashboard_repository.dart';

/// Single source of truth repository registry for the application.
/// Ensures all screens, forms, dialogs, and background tasks share consistent data.
class AppRepositories {
  static AppRepositories _instance = AppRepositories._internal();
  static AppRepositories get instance => _instance;

  late ProductRepository productRepo;
  late CategoryRepository categoryRepo;
  late InventoryRepository inventoryRepo;
  late SalesRepository salesRepo;
  late CustomerRepository customerRepo;
  late SupplierRepository supplierRepo;
  late PurchaseRepository purchaseRepo;
  late ExpenseRepository expenseRepo;
  late EmployeeRepository employeeRepo;
  late DashboardRepository dashboardRepo;

  AppRepositories._internal() {
    _init();
  }

  void _init() {
    productRepo = MockProductRepository();
    categoryRepo = MockCategoryRepository();
    inventoryRepo = MockInventoryRepository();
    salesRepo = MockSalesRepository();
    customerRepo = MockCustomerRepository();
    supplierRepo = MockSupplierRepository();
    purchaseRepo = MockPurchaseRepository();
    expenseRepo = MockExpenseRepository();
    employeeRepo = MockEmployeeRepository();
    dashboardRepo = MockDashboardRepository(
      salesRepo: salesRepo,
      productRepo: productRepo,
      expenseRepo: expenseRepo,
    );
  }

  /// Resets all repositories to fresh initial mock state (useful for tests and resets).
  static void reset() {
    _instance = AppRepositories._internal();
  }
}
