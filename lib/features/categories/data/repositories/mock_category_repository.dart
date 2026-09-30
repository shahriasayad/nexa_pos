import '../../../../core/error/failures.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [
    Category(id: '1', name: 'Electronics', description: 'Gadgets', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Category(id: '2', name: 'Accessories', description: 'Peripherals', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];

  @override
  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_categories);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Category> addCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (await checkNameExists(category.name)) {
      throw const BusinessFailure('Category name already exists.');
    }
    _categories.add(category);
    return category;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (await checkNameExists(category.name, excludeId: category.id)) {
      throw const BusinessFailure('Category name already exists.');
    }
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) throw const BusinessFailure('Category not found.');
    _categories[index] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<bool> checkNameExists(String name, {String? excludeId}) async {
    return _categories.any((c) => c.name.toLowerCase() == name.toLowerCase() && c.id != excludeId);
  }
}
