import 'package:flutter/material.dart';
import 'package:nexa_pos/core/auth/auth_provider.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/features/employees/domain/models/employee.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget? child;
  final Widget? body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? currentRoute;
  final bool showBottomNav;

  const AppShell({
    super.key,
    required this.title,
    this.child,
    this.body,
    this.actions,
    this.floatingActionButton,
    this.currentRoute,
    this.showBottomNav = true,
  }) : assert(child != null || body != null, 'Either child or body must be provided');

  Widget get _content => body ?? child!;

  @override
  Widget build(BuildContext context) {
    final route = currentRoute ??
        ModalRoute.of(context)?.settings.name ??
        AppRoutes.dashboard;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              centerTitle: false,
              actions: [
                ...?actions,
                const SizedBox(width: 8),
              ],
            ),
      drawer: isDesktop ? null : AppDrawer(currentRoute: route),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: (!isDesktop && showBottomNav)
          ? _buildMobileBottomNav(context, route)
          : null,
      body: isDesktop
          ? Row(
              children: [
                AppSidebar(currentRoute: route),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(context, route),
                      Expanded(child: _content),
                    ],
                  ),
                ),
              ],
            )
          : _content,
    );
  }

  Widget _buildDesktopHeader(BuildContext context, String route) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Breadcrumb calculation
    String sectionName = 'Overview';
    if (route == AppRoutes.pos || route == AppRoutes.transactions) {
      sectionName = 'Sales';
    } else if (route == AppRoutes.products ||
        route == AppRoutes.categories ||
        route == AppRoutes.inventory) {
      sectionName = 'Catalog';
    } else if (route == AppRoutes.customers ||
        route == AppRoutes.suppliers ||
        route == AppRoutes.purchases ||
        route == AppRoutes.expenses) {
      sectionName = 'Business';
    } else if (route == AppRoutes.employees) {
      sectionName = 'System';
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEXA POS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              Text(
                sectionName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Quick Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Terminal 01 • Shift Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryStrong,
                  ),
                ),
              ],
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context, String currentRoute) {
    int currentIndex = 0;
    if (currentRoute == AppRoutes.pos) {
      currentIndex = 1;
    } else if (currentRoute == AppRoutes.products) {
      currentIndex = 2;
    } else if (currentRoute == AppRoutes.transactions) {
      currentIndex = 3;
    } else if (currentRoute != AppRoutes.dashboard) {
      currentIndex = 4; // More
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      height: 64,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            if (currentRoute != AppRoutes.dashboard) {
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            }
            break;
          case 1:
            if (currentRoute != AppRoutes.pos) {
              Navigator.pushReplacementNamed(context, AppRoutes.pos);
            }
            break;
          case 2:
            if (currentRoute != AppRoutes.products) {
              Navigator.pushReplacementNamed(context, AppRoutes.products);
            }
            break;
          case 3:
            if (currentRoute != AppRoutes.transactions) {
              Navigator.pushReplacementNamed(context, AppRoutes.transactions);
            }
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: 'POS',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Sales',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu),
          label: 'More',
        ),
      ],
    );
  }
}

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          _buildBrand(context, isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              children: _buildNavItems(context, currentRoute),
            ),
          ),
          _buildUserArea(context, isDark),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NEXA POS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
                Text(
                  'Retail Management',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserArea(BuildContext context, bool isDark) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, _) {
        final user = AuthProvider.instance.currentUser;
        final name = user?.name ?? 'Admin User';
        final email = user?.email ?? 'admin@nexapos.com';
        final role = user?.role.displayName ?? 'Admin';

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              StatusBadge(
                label: role,
                type: role == 'Admin' ? BadgeType.success : BadgeType.info,
              ),
            ],
          ),
        );
      },
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: AppColors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXA POS',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Retail Suite v1.0',
                          style: TextStyle(
                            color: AppColors.primarySoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ListenableBuilder(
                  listenable: AuthProvider.instance,
                  builder: (context, _) {
                    final user = AuthProvider.instance.currentUser;
                    return Text(
                      'Signed in as ${user?.name ?? 'Admin'} (${user?.role.displayName ?? 'Admin'})',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.xs,
              ),
              children: _buildNavItems(context, currentRoute),
            ),
          ),
          // User role quick switch in drawer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Switch Role',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                PopupMenuButton<EmployeeRole>(
                  tooltip: 'Switch user role',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceMuted
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AuthProvider.instance.currentUser?.role.displayName ?? 'Role',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: EmployeeRole.admin,
                      child: Text('Admin'),
                    ),
                    const PopupMenuItem(
                      value: EmployeeRole.manager,
                      child: Text('Manager'),
                    ),
                    const PopupMenuItem(
                      value: EmployeeRole.cashier,
                      child: Text('Cashier'),
                    ),
                  ],
                  onSelected: (role) async {
                    final emps = await AuthProvider.instance.repository.getEmployees();
                    final match = emps.firstWhere(
                      (e) => e.role == role,
                      orElse: () => emps.first,
                    );
                    AuthProvider.instance.switchUser(match);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildNavItems(BuildContext context, String currentRoute) {
  return [
    const _NavGroupTitle(title: 'Overview'),
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      title: 'Dashboard',
      route: AppRoutes.dashboard,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.xs),

    const _NavGroupTitle(title: 'Sales & Orders'),
    _NavItem(
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale,
      title: 'POS Checkout',
      route: AppRoutes.pos,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      title: 'Sales History',
      route: AppRoutes.transactions,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.xs),

    const _NavGroupTitle(title: 'Catalog & Inventory'),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      title: 'Products',
      route: AppRoutes.products,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      title: 'Categories',
      route: AppRoutes.categories,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.warehouse_outlined,
      activeIcon: Icons.warehouse,
      title: 'Inventory',
      route: AppRoutes.inventory,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.xs),

    const _NavGroupTitle(title: 'Business Management'),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      title: 'Customers',
      route: AppRoutes.customers,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
      title: 'Suppliers',
      route: AppRoutes.suppliers,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.shopping_cart_checkout,
      activeIcon: Icons.shopping_cart,
      title: 'Purchases',
      route: AppRoutes.purchases,
      currentRoute: currentRoute,
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      title: 'Expenses',
      route: AppRoutes.expenses,
      currentRoute: currentRoute,
    ),
    const SizedBox(height: AppSpacing.xs),

    const _NavGroupTitle(title: 'Administration'),
    _NavItem(
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12, top: 10, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String title;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.title,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.normal),
          onTap: () {
            if (!isSelected) {
              Navigator.pushReplacementNamed(context, route);
            } else if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.darkSurfaceMuted : AppColors.primarySoft)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.normal),
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? (activeIcon ?? icon) : icon,
                  size: 19,
                  color: isSelected
                      ? (isDark ? AppColors.darkSuccess : AppColors.primary)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.primaryStrong)
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textPrimary),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSuccess : AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
