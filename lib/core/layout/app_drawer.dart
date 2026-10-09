import 'package:flutter/material.dart';

import '../navigation/app_router.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentRoute =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Center(
              child: Text(
                'Nexa POS',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentRoute == AppRoutes.dashboard,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Products'),
            selected: currentRoute == AppRoutes.products,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.products),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            selected: currentRoute == AppRoutes.categories,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.categories),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Inventory'),
            selected: currentRoute == AppRoutes.inventory,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.inventory),
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('POS Checkout'),
            selected: currentRoute == AppRoutes.pos,
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.pos),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Transactions'),
            selected: currentRoute == AppRoutes.transactions,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.transactions),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Customers'),
            selected: currentRoute == AppRoutes.customers,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.customers),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Suppliers'),
            selected: currentRoute == AppRoutes.suppliers,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.suppliers),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_checkout),
            title: const Text('Purchases'),
            selected: currentRoute == AppRoutes.purchases,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.purchases),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Expenses'),
            selected: currentRoute == AppRoutes.expenses,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.expenses),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Employees'),
            selected: currentRoute == AppRoutes.employees,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.employees),
          ),
        ],
      ),
    );
  }
}
