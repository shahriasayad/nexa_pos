import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/error/failures.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../employees/domain/models/employee.dart';

class ProductController extends ChangeNotifier {
  final ProductRepository productRepo;
  final CategoryRepository categoryRepo;

  ProductController({required this.productRepo, required this.categoryRepo});

  ViewState state = ViewState.initial;
  String? errorMessage;
  
  List<Product> products = [];
  List<Category> categories = [];
  
  String? searchQuery;
  String? selectedCategoryId;
  StockStatus? selectedStockStatus;
  bool? isActiveFilter;

  Future<void> loadProducts() async {
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
        bool matchesActive = isActiveFilter == null || p.isActive == isActiveFilter;
        return matchesStock && matchesActive;
      }).toList();
      
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
    loadProducts();
  }
  
  void setCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    loadProducts();
  }

  void setStockStatus(StockStatus? status) {
    selectedStockStatus = status;
    loadProducts();
  }

  void setActiveFilter(bool? active) {
    isActiveFilter = active;
    loadProducts();
  }


  Future<bool> saveProduct(Product product) async {
    if (!AuthProvider.instance.can(Permission.manageProducts)) {
      errorMessage = 'Permission denied: Cannot manage products.';
      notifyListeners();
      return false;
    }
    
    try {
      if (product.id.isEmpty) {
        await productRepo.addProduct(
          product.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await productRepo.updateProduct(product.copyWith(updatedAt: DateTime.now()));
      }
      await loadProducts();
      return true;
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    if (!AuthProvider.instance.can(Permission.manageProducts)) {
      errorMessage = 'Permission denied: Cannot manage products.';
      notifyListeners();
      return false;
    }
    
    try {
      await productRepo.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete product.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
