import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/inventory/domain/models/stock_movement.dart';
import 'package:nexa_pos/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:nexa_pos/features/products/domain/models/product.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Product product;
  final InventoryController controller;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qtyController;
  late TextEditingController _reasonController;
  late TextEditingController _noteController;

  bool _isIncrease = true;
  StockMovementType _type = StockMovementType.manualAdjustment;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _reasonController = TextEditingController(text: 'Physical inventory audit');
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final qty = int.tryParse(_qtyController.text) ?? 0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity must be greater than 0')),
        );
        return;
      }

      final change = _isIncrease ? qty : -qty;
      final newStock = widget.product.stockQuantity + change;
      if (newStock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock cannot be negative.')),
        );
        return;
      }

      final success = await widget.controller.adjustStock(
        product: widget.product,
        quantityChange: change,
        type: _type,
        reason: _reasonController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final parsedQty = int.tryParse(_qtyController.text) ?? 0;
    final simulatedChange = _isIncrease ? parsedQty : -parsedQty;
    final projectedStock = widget.product.stockQuantity + simulatedChange;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adjust Stock Level',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.product.name} (SKU: ${widget.product.sku})',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Stock projection card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.normal),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Current Stock',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.product.stockQuantity}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, size: 18),
                        Column(
                          children: [
                            const Text(
                              'New Stock',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$projectedStock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: projectedStock < 0
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Segmented Add / Deduct
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.add_circle_outline, size: 16),
                        label: Text('Add Stock'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.remove_circle_outline, size: 16),
                        label: Text('Deduct Stock'),
                      ),
                    ],
                    selected: {_isIncrease},
                    onSelectionChanged: (val) {
                      setState(() {
                        _isIncrease = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Adjustment Type
                  DropdownButtonFormField<StockMovementType>(
                    decoration: const InputDecoration(
                      labelText: 'Adjustment Type',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    initialValue: _type,
                    items: StockMovementType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quantity
                  TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to adjust *',
                      hintText: 'e.g. 5',
                      prefixIcon: Icon(Icons.numbers, size: 18),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a positive quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Adjustment *',
                      hintText: 'e.g. Damaged inventory, stocktake discrepancy',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Reason is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Optional Notes
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Internal Notes (Optional)',
                      hintText: 'Additional details or reference notes',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Cancel',
                          variant: CustomButtonVariant.outline,
                          height: 42,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          label: 'Apply Adjustment',
                          variant: CustomButtonVariant.primary,
                          height: 42,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
