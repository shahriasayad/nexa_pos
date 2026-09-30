import 'package:flutter/material.dart';
import 'package:nexa_pos/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nexa_pos/features/products/presentation/screens/product_list_screen.dart';
import 'package:nexa_pos/features/categories/presentation/screens/category_list_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String products = '/products';
  static const String categories = '/categories';
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
