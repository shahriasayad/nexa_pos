import 'package:flutter/material.dart';

import '../../../../core/state/view_state.dart';
import '../../domain/models/purchase_order.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../inventory/domain/models/stock_movement.dart';
import '../../../products/domain/repositories/product_repository.dart';

class PurchaseController extends ChangeNotifier {
  final PurchaseRepository purchaseRepo;
  final InventoryRepository inventoryRepo;
  final ProductRepository productRepo;

  PurchaseController({
    required this.purchaseRepo,
    required this.inventoryRepo,
    required this.productRepo,
  });

  ViewState state = ViewState.initial;
  String? errorMessage;

  List<PurchaseOrder> purchases = [];
  String? currentSupplierId;
  PurchaseStatus? currentStatus;

  Future<void> loadPurchases({
    String? supplierId,
    PurchaseStatus? status,
  }) async {
    currentSupplierId = supplierId;
    currentStatus = status;
    _setState(ViewState.loading);
    try {
      purchases = await purchaseRepo.getPurchases(
        supplierId: supplierId,
        status: status,
      );
      _setState(purchases.isEmpty ? ViewState.empty : ViewState.success);
    } catch (e) {
      errorMessage = e.toString();
      _setState(ViewState.error);
    }
  }

  Future<bool> savePurchase(PurchaseOrder purchase) async {
    try {
      final existing = await purchaseRepo.getPurchaseById(purchase.id);
      if (existing != null) {
        await purchaseRepo.updatePurchase(purchase);
      } else {
        await purchaseRepo.savePurchase(purchase);
      }
      await loadPurchases(supplierId: currentSupplierId, status: currentStatus);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> receivePurchase(
    PurchaseOrder purchase,
    List<PurchaseItem> receivedItems,
  ) async {
    try {
      // 1. Update Inventory for each item
      for (final item in receivedItems) {
        if (item.receivedQuantity <= 0) continue;

        final product = await productRepo.getProductById(item.productId);
        if (product == null) {
          throw Exception('Product not found: ${item.productName}');
        }

        final newStock = product.stockQuantity + item.receivedQuantity;

        await productRepo.updateProduct(
          product.copyWith(stockQuantity: newStock, updatedAt: DateTime.now()),
        );

        await inventoryRepo.logMovement(
          StockMovement(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                item.productId,
            productId: item.productId,
            quantityChange: item.receivedQuantity,
            type: StockMovementType.purchase,
            previousStock: product.stockQuantity,
            newStock: newStock,
            reason: 'Purchase order received',
            referenceId: purchase.id,
            timestamp: DateTime.now(),
          ),
        );
      }

      // 2. Update Purchase Order status
      final updatedPurchase = purchase.copyWith(
        status: PurchaseStatus.received,
        items: receivedItems, // Contains the updated receivedQuantity for each item
      );

      await purchaseRepo.updatePurchase(updatedPurchase);
      await loadPurchases(supplierId: currentSupplierId, status: currentStatus);

      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _setState(ViewState newState) {
    state = newState;
    notifyListeners();
  }
}
