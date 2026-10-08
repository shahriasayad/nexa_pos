import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/core/theme/app_typography.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? currentRoute;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final route = currentRoute ?? ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(title),
              actions: actions,
            ),
      drawer: isDesktop ? null : AppDrawer(currentRoute: route),
      floatingActionButton: floatingActionButton,
      body: isDesktop
          ? Row(
              children: [
                AppSidebar(currentRoute: route),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(context),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            )
          : child,
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerTheme.color!),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildBrand(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: _buildNavItems(context, currentRoute),
            ),
          ),
          _buildUserArea(context),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerTheme.color!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'NEXA POS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerTheme.color!),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Text(
              'A',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin User', style: Theme.of(context).textTheme.bodyMedium),
                Text('admin@nexapos.com', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Center(
              child: Text(
                'NEXA POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildNavItems(context, currentRoute),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildNavItems(BuildContext context, String currentRoute) {
  return [
    _NavGroupTitle(title: 'Overview'),
    _NavItem(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      route: AppRoutes.dashboard,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.md),
    
    _NavGroupTitle(title: 'Sales'),
    _NavItem(
      icon: Icons.point_of_sale,
      title: 'POS Checkout',
      route: AppRoutes.pos,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      title: 'Sales History',
      route: AppRoutes.transactions,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.md),
    
    _NavGroupTitle(title: 'Catalog'),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      title: 'Products',
      route: AppRoutes.products,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.category_outlined,
      title: 'Categories',
      route: AppRoutes.categories,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.store_outlined,
      title: 'Inventory',
      route: AppRoutes.inventory,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.md),
    
    _NavGroupTitle(title: 'Business'),
    _NavItem(
      icon: Icons.people_outline,
      title: 'Customers',
      route: AppRoutes.customers,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.business_outlined,
      title: 'Suppliers',
      route: AppRoutes.suppliers,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.shopping_cart_checkout,
      title: 'Purchases',
      route: AppRoutes.purchases,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Expenses',
      route: AppRoutes.expenses,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.md),

    _NavGroupTitle(title: 'System'),
    _NavItem(
      icon: Icons.badge_outlined,
      title: 'Employees',
      route: AppRoutes.employees,
      currentRoute: currentRoute,
    ),
  ];
}

class _NavGroupTitle extends StatelessWidget {
  final String title;
  const _NavGroupTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 16, top: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.normal),
        ),
        leading: Icon(icon),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        selected: isSelected,
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          } else if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
            Navigator.pop(context); // Close drawer
          }
        },
      ),
    );
  }
}
