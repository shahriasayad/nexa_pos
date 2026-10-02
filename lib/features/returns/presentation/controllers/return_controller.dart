import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../features/pos/domain/models/sale_transaction.dart';
import '../../../../features/pos/domain/repositories/sales_repository.dart';
import '../../../../features/products/domain/repositories/product_repository.dart';
import '../../../../features/inventory/domain/models/stock_movement.dart';
import '../../../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../domain/models/return_transaction.dart';

class ReturnController extends ChangeNotifier {
  final SalesRepository salesRepo;
  final ProductRepository productRepo;
  final InventoryRepository inventoryRepo;

  ReturnController({
    required this.salesRepo,
    required this.productRepo,
    required this.inventoryRepo,
  });

  ViewState state = ViewState.initial;
  String? errorMessage;
  
  Map<String, int> returnQuantities = {};
  ReturnReason selectedReason = ReturnReason.changedMind;
  PaymentMethod refundMethod = PaymentMethod.cash;

  void setReturnQuantity(String productId, int quantity, int maxAllowed) {
    if (quantity < 0) return;
    if (quantity > maxAllowed) {
      errorMessage = 'Cannot return more than purchased.';
      notifyListeners();
      return;
    }
    errorMessage = null;
    returnQuantities[productId] = quantity;
    notifyListeners();
  }

  double calculateRefundAmount(SaleTransaction sale) {
    double total = 0;
    for (var item in sale.items) {
      final qty = returnQuantities[item.productId] ?? 0;
      total += qty * item.unitPrice;
    }
    return total;
  }

  Future<bool> submitReturn(SaleTransaction sale) async {
    if (returnQuantities.values.every((q) => q == 0)) {
      errorMessage = 'Please select at least one item to return.';
      notifyListeners();
      return false;
    }

    state = ViewState.loading;
    notifyListeners();

    try {
      final refundAmount = calculateRefundAmount(sale);
      
      final returnItems = <ReturnItem>[];
      for (var item in sale.items) {
        final qty = returnQuantities[item.productId] ?? 0;
        if (qty > 0) {
          returnItems.add(ReturnItem(
            productId: item.productId,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: qty,
            refundAmount: qty * item.unitPrice,
          ));
        }
      }

      final returnTx = ReturnTransaction(
        id: 'RET-${DateTime.now().millisecondsSinceEpoch}',
        originalTransactionId: sale.id,
        timestamp: DateTime.now(),
        items: returnItems,
        totalRefund: refundAmount,
        refundMethod: refundMethod,
        reason: selectedReason,
      );

      // Save return
      await salesRepo.returnItems(sale.id, returnTx);

      // Add to inventory
      for (var rItem in returnItems) {
        final product = await productRepo.getProductById(rItem.productId);
        if (product != null) {
          final newStock = product.stockQuantity + rItem.quantity;
          await productRepo.updateProduct(product.copyWith(stockQuantity: newStock));
          
          await inventoryRepo.logMovement(StockMovement(
            id: 'MOV-${DateTime.now().millisecondsSinceEpoch}-${rItem.productId}',
            productId: rItem.productId,
            quantityChange: rItem.quantity,
            type: StockMovementType.returnItem,
            previousStock: product.stockQuantity,
            newStock: newStock,
            reason: 'Return: ${selectedReason.name}',
            referenceId: returnTx.id,
            timestamp: DateTime.now(),
          ));
        }
      }

      state = ViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      state = ViewState.error;
      notifyListeners();
      return false;
    }
  }
}
