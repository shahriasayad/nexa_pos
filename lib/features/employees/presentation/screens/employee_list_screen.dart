import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/employees/domain/models/employee.dart';
import 'package:nexa_pos/features/employees/presentation/controllers/employee_controller.dart';
import 'package:nexa_pos/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/data_table_view.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/error_view.dart';
import 'package:nexa_pos/shared/widgets/filter_toolbar.dart';
import 'package:nexa_pos/shared/widgets/kpi_card.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';
import 'package:nexa_pos/shared/widgets/status_badge.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  late EmployeeController _controller;
  final TextEditingController _searchController = TextEditingController();
  EmployeeRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController(repository: AppRepositories.instance.employeeRepo);
    _controller.loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openEmployeeForm([Employee? employee]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (result == true) {
      _controller.loadEmployees(query: _searchController.text);
    }
  }

  List<Employee> _getFilteredEmployees() {
    return _controller.employees.where((emp) {
      final matchesRole = _roleFilter == null || emp.role == _roleFilter;
      return matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.employees,
      title: 'Employees',
      actions: [
        CustomButton(
          label: 'Add Employee',
          icon: Icons.person_add_alt_1_rounded,
          variant: CustomButtonVariant.primary,
          height: 38,
          onPressed: () => _openEmployeeForm(),
        ),
      ],
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final filtered = _getFilteredEmployees();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPageHeader(
                  title: 'Staff Directory & Access Control',
                  subtitle:
                      'Manage staff accounts, assign POS terminal roles, and configure security permissions.',
                  actions: [
                    CustomButton(
                      label: 'Add Employee',
                      icon: Icons.person_add_alt_1_rounded,
                      variant: CustomButtonVariant.primary,
                      height: 40,
                      onPressed: () => _openEmployeeForm(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Top KPI Metrics
                _buildMetricsOverview(),
                const SizedBox(height: AppSpacing.lg),

                // Filter Toolbar
                PosFilterToolbar(
                  searchHint: 'Search staff by name or email...',
                  searchValue: _searchController.text,
                  onSearchChanged: (val) {
                    _searchController.text = val;
                    _controller.loadEmployees(query: val);
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    _controller.loadEmployees();
                  },
                  filters: [
                    FilterChip(
                      label: const Text('All Roles'),
                      selected: _roleFilter == null,
                      onSelected: (val) {
                        if (val) setState(() => _roleFilter = null);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...EmployeeRole.values.map((role) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(role.displayName),
                          selected: _roleFilter == role,
                          onSelected: (val) {
                            setState(() {
                              _roleFilter = val ? role : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Content View
                _buildEmployeeContent(context, filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final staff = _controller.employees;
    final total = staff.length;
    final active = staff.where((e) => e.isActive).length;
    final adminsAndManagers = staff
        .where((e) =>
            e.role == EmployeeRole.admin || e.role == EmployeeRole.manager)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final count = isWide ? 3 : 1;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: isWide ? 2.5 : 3.0,
          children: [
            PosKpiCard(
              title: 'Total Staff Members',
              value: '$total',
              icon: Icons.badge_outlined,
              color: AppColors.primary,
            ),
            PosKpiCard(
              title: 'Active Accounts',
              value: '$active / $total',
              icon: Icons.verified_user_outlined,
              color: AppColors.success,
            ),
            PosKpiCard(
              title: 'Admins & Managers',
              value: '$adminsAndManagers',
              icon: Icons.admin_panel_settings_outlined,
              color: AppColors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeContent(BuildContext context, List<Employee> employees) {
    if (_controller.state == ViewState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(message: 'Loading staff directory...'),
      );
    }
    if (_controller.state == ViewState.error) {
      return ErrorView(
        message: _controller.errorMessage ?? 'Error loading employees',
        onRetry: () => _controller.loadEmployees(),
      );
    }
    if (employees.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline,
        title: 'No Staff Records',
        description: _searchController.text.isNotEmpty || _roleFilter != null
            ? 'No employees matched your search and role filters.'
            : 'Add cashiers and managers to grant terminal access.',
        actionLabel: 'Add First Employee',
        onAction: () => _openEmployeeForm(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        if (isDesktop) {
          return _buildDesktopTable(context, employees);
        } else {
          return _buildMobileCardList(context, employees);
        }
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<Employee> employees) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PosDataTable(
      columns: const [
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Contact')),
        DataColumn(label: Text('Permissions')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: employees.map((emp) {
        final initials = emp.name.isNotEmpty
            ? emp.name
                .trim()
                .split(' ')
                .take(2)
                .map((e) => e.isNotEmpty ? e[0] : '')
                .join()
                .toUpperCase()
            : '?';

        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: emp.isActive
                        ? AppColors.primarySoft
                        : (isDark
                            ? AppColors.darkSurfaceMuted
                            : AppColors.surfaceMuted),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: emp.isActive
                            ? AppColors.primaryStrong
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    emp.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              onTap: () => _openEmployeeForm(emp),
            ),
            DataCell(
              StatusBadge(
                label: emp.role.displayName.toUpperCase(),
                type: emp.role == EmployeeRole.admin
                    ? StatusType.danger
                    : emp.role == EmployeeRole.manager
                        ? StatusType.info
                        : StatusType.neutral,
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emp.email, style: const TextStyle(fontSize: 12)),
                  if (emp.phone != null && emp.phone!.isNotEmpty)
                    Text(
                      emp.phone!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(
              Text(
                emp.customPermissions.isNotEmpty
                    ? '${emp.customPermissions.length} custom'
                    : '${emp.role.defaultPermissions.length} standard',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            DataCell(
              StatusBadge(
                label: emp.isActive ? 'ACTIVE' : 'INACTIVE',
                type: emp.isActive ? StatusType.success : StatusType.neutral,
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Profile & Access',
                onPressed: () => _openEmployeeForm(emp),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileCardList(BuildContext context, List<Employee> employees) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: employees.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final emp = employees[index];
        final initials = emp.name.isNotEmpty
            ? emp.name
                .trim()
                .split(' ')
                .take(2)
                .map((e) => e.isNotEmpty ? e[0] : '')
                .join()
                .toUpperCase()
            : '?';

        return CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InkWell(
            onTap: () => _openEmployeeForm(emp),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: emp.isActive
                      ? AppColors.primarySoft
                      : (isDark
                          ? AppColors.darkSurfaceMuted
                          : AppColors.surfaceMuted),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: emp.isActive
                          ? AppColors.primaryStrong
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emp.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: emp.role.displayName.toUpperCase(),
                      type: emp.role == EmployeeRole.admin
                          ? StatusType.danger
                          : emp.role == EmployeeRole.manager
                              ? StatusType.info
                              : StatusType.neutral,
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: emp.isActive ? 'ACTIVE' : 'INACTIVE',
                      type: emp.isActive
                          ? StatusType.success
                          : StatusType.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
