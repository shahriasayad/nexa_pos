import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/error/failures.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../domain/models/stock_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../employees/domain/models/employee.dart';

class InventoryController extends ChangeNotifier {
  final ProductRepository productRepo;
  final CategoryRepository categoryRepo;
  final InventoryRepository inventoryRepo;

  InventoryController({
    required this.productRepo,
    required this.categoryRepo,
    required this.inventoryRepo,
  });

  ViewState state = ViewState.initial;
  String? errorMessage;
  
  List<Product> products = [];
  List<Category> categories = [];
  Map<String, StockMovement> lastMovements = {};

  String? searchQuery;
  String? selectedCategoryId;
  StockStatus? selectedStockStatus;

  Future<void> loadInventory() async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      if (categories.isEmpty) {
        categories = await categoryRepo.getCategories();
      }
      
      var rawProducts = await productRepo.getProducts(
        search: searchQuery,
        categoryId: selectedCategoryId,
      );

      products = rawProducts.where((p) {
        bool matchesStock = selectedStockStatus == null || p.stockStatus == selectedStockStatus;
        return matchesStock;
      }).toList();

      for (var p in products) {
        final movements = await inventoryRepo.getMovementsForProduct(p.id);
        if (movements.isNotEmpty) {
          lastMovements[p.id] = movements.first;
        }
      }
      
      state = products.isEmpty ? ViewState.empty : ViewState.success;
    } catch (e) {
      state = ViewState.error;
      errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void setSearch(String? query) {
    searchQuery = (query != null && query.trim().isNotEmpty) ? query.trim() : null;
    loadInventory();
  }
  
  void setCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    loadInventory();
  }

  void setStockStatus(StockStatus? status) {
    selectedStockStatus = status;
    loadInventory();
  }

  Future<bool> adjustStock({
    required Product product,
    required int quantityChange,
    required StockMovementType type,
    required String reason,
    String? note,
  }) async {
    if (!AuthProvider.instance.can(Permission.manageInventory)) {
      errorMessage = 'Permission denied: Cannot manage inventory.';
      notifyListeners();
      return false;
    }

    if (quantityChange == 0) {
      errorMessage = 'Quantity change cannot be zero.';
      notifyListeners();
      return false;
    }

    final newStock = product.stockQuantity + quantityChange;
    if (newStock < 0) {
      errorMessage = 'Stock cannot be negative.';
      notifyListeners();
      return false;
    }

    try {
      final updatedProduct = product.copyWith(stockQuantity: newStock, updatedAt: DateTime.now());
      await productRepo.updateProduct(updatedProduct);

      final movement = StockMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        quantityChange: quantityChange,
        type: type,
        previousStock: product.stockQuantity,
        newStock: newStock,
        reason: reason,
        note: note,
        timestamp: DateTime.now(),
      );
      await inventoryRepo.logMovement(movement);

      await loadInventory();
      return true;
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Unexpected error during stock adjustment.';
      notifyListeners();
      return false;
    }
  }

  Future<List<StockMovement>> getProductMovements(String productId) async {
    try {
      return await inventoryRepo.getMovementsForProduct(productId);
    } catch (e) {
      return [];
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
