import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/customers/domain/models/customer.dart';
import 'package:nexa_pos/features/customers/presentation/controllers/customer_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  final CustomerController controller;

  const CustomerFormScreen({
    super.key,
    this.customer,
    required this.controller,
  });

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    _notesController = TextEditingController(
      text: widget.customer?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id:
            widget.customer?.id ??
            'CUST-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        totalSpending: widget.customer?.totalSpending ?? 0.0,
        outstandingBalance: widget.customer?.outstandingBalance ?? 0.0,
        loyaltyPoints: widget.customer?.loyaltyPoints ?? 0,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
      );

      final success = await widget.controller.saveCustomer(customer);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to remove "${widget.customer!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.controller.deleteCustomer(widget.customer!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      currentRoute: AppRoutes.customers,
      title: isEditing ? 'Edit Customer' : 'Add Customer',
      actions: [
        CustomButton(
          label: 'Cancel',
          variant: CustomButtonVariant.outline,
          height: 38,
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return CustomButton(
              label: isEditing ? 'Save Changes' : 'Create Customer',
              icon: Icons.check,
              variant: CustomButtonVariant.primary,
              isLoading: widget.controller.state == ViewState.loading,
              height: 38,
              onPressed: widget.controller.state == ViewState.loading
                  ? null
                  : _save,
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
                    title: isEditing ? 'Edit Customer' : 'Create Customer',
                    subtitle: isEditing
                        ? 'Update account profile and contact details for ${widget.customer!.name}.'
                        : 'Register a new customer for loyalty rewards and checkout tracking.',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: Customer Identity & Contact
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
                              'Profile & Contact',
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
                            hintText: 'e.g. John Doe',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Customer name is required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g. +1 555-0199',
                                  prefixIcon:
                                      Icon(Icons.phone_outlined, size: 20),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'e.g. john@example.com',
                                  prefixIcon:
                                      Icon(Icons.email_outlined, size: 20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Address & Preferences
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Address & Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Physical Address',
                            hintText: 'Street address, Suite, City, State, ZIP',
                            prefixIcon: Icon(Icons.home_outlined, size: 20),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Notes & Preferences',
                            hintText: 'Special instructions, preferred items, remarks...',
                            prefixIcon: Icon(Icons.notes_outlined, size: 20),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  // Section 3: If existing, Account History Card
                  if (isEditing) ...[
                    const SizedBox(height: AppSpacing.lg),
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_outlined,
                                  size: 20, color: AppColors.primary),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Account Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Lifetime Spending',
                                '\$${widget.customer!.totalSpending.toStringAsFixed(2)}',
                                AppColors.primary,
                              ),
                              _buildStatItem(
                                'Loyalty Points',
                                '${widget.customer!.loyaltyPoints} pts',
                                AppColors.orange,
                              ),
                              _buildStatItem(
                                'Outstanding Balance',
                                '\$${widget.customer!.outstandingBalance.toStringAsFixed(2)}',
                                widget.customer!.outstandingBalance > 0
                                    ? AppColors.warning
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      if (isEditing)
                        CustomButton(
                          label: 'Delete Customer',
                          icon: Icons.delete_outline,
                          variant: CustomButtonVariant.danger,
                          height: 42,
                          onPressed: widget.controller.state == ViewState.loading
                              ? null
                              : _delete,
                        ),
                      const Spacer(),
                      CustomButton(
                        label: 'Cancel',
                        variant: CustomButtonVariant.outline,
                        height: 42,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          return CustomButton(
                            label: isEditing ? 'Save Changes' : 'Create Customer',
                            icon: Icons.check,
                            variant: CustomButtonVariant.primary,
                            isLoading: widget.controller.state == ViewState.loading,
                            height: 42,
                            onPressed: widget.controller.state == ViewState.loading
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
