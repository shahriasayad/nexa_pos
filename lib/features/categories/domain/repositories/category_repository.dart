import '../models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category?> getCategoryById(String id);
  Future<Category> addCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<bool> checkNameExists(String name, {String? excludeId});
}
