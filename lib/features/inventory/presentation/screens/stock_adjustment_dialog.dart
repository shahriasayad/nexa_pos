import 'package:flutter/material.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/models/stock_movement.dart';
import '../controllers/inventory_controller.dart';

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
    _reasonController = TextEditingController();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be greater than 0')));
        return;
      }
      
      final change = _isIncrease ? qty : -qty;
      final newStock = widget.product.stockQuantity + change;
      if (newStock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock cannot be negative.')));
        return;
      }

      final success = await widget.controller.adjustStock(
        product: widget.product,
        quantityChange: change,
        type: _type,
        reason: _reasonController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${widget.product.stockQuantity}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Add'),
                      value: true,
                      groupValue: _isIncrease,
                      onChanged: (v) => setState(() => _isIncrease = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Remove'),
                      value: false,
                      groupValue: _isIncrease,
                      onChanged: (v) => setState(() => _isIncrease = v!),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<StockMovementType>(
                decoration: const InputDecoration(labelText: 'Type'),
                value: _type,
                items: StockMovementType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name),
                )).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Quantity *'),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid quantity' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason *'),
                validator: (v) => v == null || v.isEmpty ? 'Reason required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Apply')),
      ],
    );
  }
}
