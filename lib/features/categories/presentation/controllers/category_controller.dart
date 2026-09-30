import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/error/failures.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';

class CategoryController extends ChangeNotifier {
  final CategoryRepository categoryRepo;
  final ProductRepository productRepo;

  CategoryController({required this.categoryRepo, required this.productRepo});

  ViewState state = ViewState.initial;
  String? errorMessage;
  List<Category> categories = [];

  Future<void> loadCategories() async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      categories = await categoryRepo.getCategories();
      state = categories.isEmpty ? ViewState.empty : ViewState.success;
    } catch (e) {
      state = ViewState.error;
      errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> saveCategory(Category category) async {
    try {
      if (category.id.isEmpty) {
        await categoryRepo.addCategory(
          category.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString(), createdAt: DateTime.now(), updatedAt: DateTime.now()),
        );
      } else {
        await categoryRepo.updateCategory(category.copyWith(updatedAt: DateTime.now()));
      }
      await loadCategories();
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

  Future<bool> deleteCategory(String id) async {
    try {
      final count = await productRepo.getProductCountByCategory(id);
      if (count > 0) {
        errorMessage = 'Cannot delete category with active products.';
        notifyListeners();
        return false;
      }
      await categoryRepo.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete category.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
