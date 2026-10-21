import 'package:flutter/material.dart';

import 'package:nexa_pos/core/layout/app_shell.dart';
import 'package:nexa_pos/core/navigation/app_router.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/expenses/data/repositories/mock_expense_repository.dart';
import 'package:nexa_pos/features/expenses/domain/models/expense.dart';
import 'package:nexa_pos/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/page_header.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ExpenseController _controller;

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late ExpenseCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _controller = ExpenseController(repository: MockExpenseRepository());
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: widget.expense?.note ?? '');
    _category = widget.expense?.category ?? ExpenseCategory.other;
    _date = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amount must be greater than zero'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final expense = Expense(
        id:
            widget.expense?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: amount,
        category: _category,
        date: _date,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        receiptPath: widget.expense?.receiptPath,
      );

      final success = await _controller.saveExpense(expense);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ?? 'Failed to save expense'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _delete() async {
    if (widget.expense == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to permanently delete this expense record? This action cannot be undone.',
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
      final success = await _controller.deleteExpense(widget.expense!.id);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.apartment_outlined;
      case ExpenseCategory.electricity:
        return Icons.bolt_outlined;
      case ExpenseCategory.internet:
        return Icons.wifi_outlined;
      case ExpenseCategory.salary:
        return Icons.payments_outlined;
      case ExpenseCategory.transportation:
        return Icons.local_shipping_outlined;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.other:
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      currentRoute: AppRoutes.expenses,
      title: isEditing ? 'Edit Expense' : 'Add Expense',
      actions: [
        if (isEditing)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete Expense',
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
              label: isEditing ? 'Save Changes' : 'Record Expense',
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
                    title: isEditing ? 'Edit Expense Record' : 'Record Store Expense',
                    subtitle: isEditing
                        ? 'Update transaction amount, vendor category, or notes.'
                        : 'Log operational spending, utility bills, maintenance or payroll disbursements.',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: Financial & Title Details
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Expense Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Expense Description *',
                            hintText: 'e.g. October Store Electricity Bill',
                            prefixIcon: Icon(Icons.edit_note, size: 20),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Description is required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount Disbursed *',
                                  hintText: '0.00',
                                  prefixIcon:
                                      Icon(Icons.attach_money, size: 20),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Amount is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: DropdownButtonFormField<ExpenseCategory>(
                                initialValue: _category,
                                decoration: const InputDecoration(
                                  labelText: 'Expense Category',
                                  prefixIcon:
                                      Icon(Icons.category_outlined, size: 20),
                                ),
                                items: ExpenseCategory.values.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Row(
                                      children: [
                                        Icon(_getCategoryIcon(cat), size: 16),
                                        const SizedBox(width: 8),
                                        Text(cat.displayName),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _category = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Date & Memo Notes
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.event_note_outlined,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Date & Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(AppRadius.normal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceMuted
                                  : AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.normal),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.md),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Disbursement Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Memo / Reference (Optional)',
                            hintText: 'Check number, invoice reference, or payment remarks...',
                            prefixIcon: Icon(Icons.notes_outlined, size: 20),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Actions
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
                            label: isEditing ? 'Save Changes' : 'Record Expense',
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
