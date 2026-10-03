import 'package:flutter/material.dart';
import 'package:nexa_pos/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nexa_pos/features/products/presentation/screens/product_list_screen.dart';
import 'package:nexa_pos/features/categories/presentation/screens/category_list_screen.dart';
import 'package:nexa_pos/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:nexa_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:nexa_pos/features/pos/presentation/screens/transaction_history_screen.dart';
import 'package:nexa_pos/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:nexa_pos/features/suppliers/presentation/screens/supplier_list_screen.dart';
import 'package:nexa_pos/features/purchases/presentation/screens/purchase_list_screen.dart';
import 'package:nexa_pos/features/expenses/presentation/screens/expense_list_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String inventory = '/inventory';
  static const String pos = '/pos';
  static const String transactions = '/transactions';
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String purchases = '/purchases';
  static const String expenses = '/expenses';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen(), settings: settings);
      case AppRoutes.products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen(), settings: settings);
      case AppRoutes.categories:
        return MaterialPageRoute(builder: (_) => const CategoryListScreen(), settings: settings);
      case AppRoutes.inventory:
        return MaterialPageRoute(builder: (_) => const InventoryListScreen(), settings: settings);
      case AppRoutes.pos:
        return MaterialPageRoute(builder: (_) => const PosScreen(), settings: settings);
      case AppRoutes.transactions:
        return MaterialPageRoute(builder: (_) => const TransactionHistoryScreen(), settings: settings);
      case AppRoutes.customers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen(), settings: settings);
      case AppRoutes.suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierListScreen(), settings: settings);
      case AppRoutes.purchases:
        return MaterialPageRoute(builder: (_) => const PurchaseListScreen(), settings: settings);
      case AppRoutes.expenses:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
