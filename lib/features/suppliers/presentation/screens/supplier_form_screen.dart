import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/suppliers/data/repositories/mock_supplier_repository.dart';
import 'package:nexa_pos/features/suppliers/domain/models/supplier.dart';
import 'package:nexa_pos/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late SupplierController _controller;

  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _controller = SupplierController(repository: MockSupplierRepository());
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _contactController = TextEditingController(
      text: widget.supplier?.contactName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.supplier?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier?.address ?? '',
    );
    _isActive = widget.supplier?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id:
            widget.supplier?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        contactName: _contactController.text.trim().isNotEmpty
            ? _contactController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        isActive: _isActive,
        createdAt: widget.supplier?.createdAt ?? DateTime.now(),
        outstandingBalance: widget.supplier?.outstandingBalance ?? 0.0,
      );

      final success = await _controller.saveSupplier(supplier);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _controller.errorMessage ?? 'Failed to save supplier',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      currentRoute: AppRoutes.suppliers,
      title: isEditing ? 'Edit Supplier' : 'Add Supplier',
      actions: [
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
              label: isEditing ? 'Save Changes' : 'Create Supplier',
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
                    title: isEditing ? 'Edit Supplier' : 'Add New Supplier',
                    subtitle: isEditing
                        ? 'Update vendor profile, procurement contacts, and status.'
                        : 'Register a wholesale partner or vendor for inventory restocking.',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: Business Identity
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Company & Contact Person',
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
                            labelText: 'Supplier / Company Name *',
                            hintText: 'e.g. Acme Beverage Distributors',
                            prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Supplier name is required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: 'Primary Contact Person',
                            hintText: 'e.g. Sarah Jenkins (Account Rep)',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Contact Details & Address
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_mail_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Communication & Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g. +1 800-555-0199',
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
                                  hintText: 'e.g. orders@acmedist.com',
                                  prefixIcon:
                                      Icon(Icons.email_outlined, size: 20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Physical / Warehouse Address',
                            hintText: 'Industrial Park, Warehouse #4B, City, State, ZIP',
                            prefixIcon:
                                Icon(Icons.location_on_outlined, size: 20),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 3: Operational Status
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Status & Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Active Supplier',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _isActive
                                ? 'Supplier is active and available for purchase orders.'
                                : 'Supplier is archived and cannot receive new orders.',
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
                        if (isEditing && widget.supplier!.outstandingBalance > 0) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Outstanding Balance:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '\$${widget.supplier!.outstandingBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Bottom Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                            label: isEditing ? 'Save Changes' : 'Create Supplier',
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
