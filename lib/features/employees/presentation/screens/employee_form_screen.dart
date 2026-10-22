import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/employees/domain/models/employee.dart';
import 'package:nexa_pos/features/employees/presentation/controllers/employee_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late EmployeeController _controller;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late EmployeeRole _role;
  bool _isActive = true;
  Set<Permission> _customPermissions = {};

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController(repository: AppRepositories.instance.employeeRepo);
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _emailController = TextEditingController(
      text: widget.employee?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.employee?.phone ?? '',
    );
    _role = widget.employee?.role ?? EmployeeRole.cashier;
    _isActive = widget.employee?.isActive ?? true;
    _customPermissions = widget.employee?.customPermissions ?? {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final employee = Employee(
        id:
            widget.employee?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        role: _role,
        isActive: _isActive,
        customPermissions: _customPermissions,
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
      );

      final success = await _controller.saveEmployee(employee);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _controller.errorMessage ?? 'Failed to save employee',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _delete() async {
    if (widget.employee == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: const Text(
          'Are you sure you want to delete this employee? They will lose all access to the POS system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await _controller.deleteEmployee(widget.employee!.id);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _resetToRoleDefaults() {
    setState(() {
      _customPermissions = Set.from(_role.defaultPermissions);
    });
  }

  String _formatPermissionName(Permission perm) {
    switch (perm) {
      case Permission.createSale:
        return 'Create Sales & Process Orders';
      case Permission.refund:
        return 'Issue Refunds & Returns';
      case Permission.modifyPrice:
        return 'Override / Modify Product Prices';
      case Permission.manageProducts:
        return 'Create & Edit Product Catalog';
      case Permission.manageInventory:
        return 'Adjust Stock & Inventory Transfers';
      case Permission.viewProfit:
        return 'View Cost Margins & Profit Metrics';
      case Permission.manageEmployees:
        return 'Manage Staff Members & Roles';
      case Permission.viewReports:
        return 'View Financial Reports & Analytics';
      case Permission.manageSettings:
        return 'Modify System Configuration';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      currentRoute: AppRoutes.employees,
      title: isEditing ? 'Edit Staff Profile' : 'Add Employee',
      actions: [
        if (isEditing)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete Staff Member',
            onPressed: _delete,
          ),
        CustomButton(
          label: 'Cancel',
          variant: CustomButtonVariant.outline,
          height: 38,
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return CustomButton(
              label: isEditing ? 'Save Changes' : 'Create Account',
              icon: Icons.check,
              variant: CustomButtonVariant.primary,
              isLoading: _controller.state == ViewState.loading,
              height: 38,
              onPressed: _controller.state == ViewState.loading ? null : _save,
            );
          },
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PosPageHeader(
                    title: isEditing ? 'Edit Staff Member' : 'New Employee Account',
                    subtitle: isEditing
                        ? 'Update credentials, job assignment, and operational permissions.'
                        : 'Register a cashier, manager, or administrator for system access.',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: Staff Identity & Contact
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Profile & Contact Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'e.g. Alex Morgan',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Work Email *',
                                  hintText: 'e.g. alex@nexapos.com',
                                  prefixIcon:
                                      Icon(Icons.email_outlined, size: 20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Email is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Phone',
                                  hintText: 'e.g. +1 555-0144',
                                  prefixIcon:
                                      Icon(Icons.phone_outlined, size: 20),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Role & Active Status
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Role & Account State',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<EmployeeRole>(
                          initialValue: _role,
                          decoration: const InputDecoration(
                            labelText: 'System Role',
                            prefixIcon:
                                Icon(Icons.shield_outlined, size: 20),
                          ),
                          items: EmployeeRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _role = val;
                                _customPermissions =
                                    Set.from(val.defaultPermissions);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Active Account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _isActive
                                ? 'Employee can log in and process transactions.'
                                : 'Account is deactivated and cannot log in to POS.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          value: _isActive,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 3: Granular Permissions Matrix
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.vpn_key_outlined,
                                    size: 20, color: AppColors.primary),
                                SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Security Permissions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset to Defaults'),
                              onPressed: _resetToRoleDefaults,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize access rights for this employee. By default, rights inherit from the ${_role.displayName} role.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        ...Permission.values.map((perm) {
                          final isGranted = _customPermissions.isNotEmpty
                              ? _customPermissions.contains(perm)
                              : _role.defaultPermissions.contains(perm);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _formatPermissionName(perm),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Code: ${perm.name}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.textMuted,
                              ),
                            ),
                            value: isGranted,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                if (_customPermissions.isEmpty) {
                                  _customPermissions =
                                      Set.from(_role.defaultPermissions);
                                }
                                if (val == true) {
                                  _customPermissions.add(perm);
                                } else {
                                  _customPermissions.remove(perm);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isEditing)
                        CustomButton(
                          label: 'Delete',
                          icon: Icons.delete_outline,
                          variant: CustomButtonVariant.danger,
                          height: 42,
                          onPressed: _delete,
                        ),
                      if (isEditing) const Spacer(),
                      CustomButton(
                        label: 'Cancel',
                        variant: CustomButtonVariant.outline,
                        height: 42,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return CustomButton(
                            label: isEditing ? 'Save Changes' : 'Create Employee',
                            icon: Icons.check,
                            variant: CustomButtonVariant.primary,
                            isLoading: _controller.state == ViewState.loading,
                            height: 42,
                            onPressed: _controller.state == ViewState.loading
                                ? null
                                : _save,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
