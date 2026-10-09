import '../../domain/models/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

class MockSupplierRepository implements SupplierRepository {
  final List<Supplier> _suppliers = [
    Supplier(
      id: 'sup-1',
      name: 'Global Electronics',
      contactName: 'Alice Smith',
      phone: '+1234567890',
      email: 'contact@globalelec.com',
      address: '123 Tech Lane',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Supplier(
      id: 'sup-2',
      name: 'Fresh Foods Dist',
      contactName: 'Bob Johnson',
      phone: '+1987654321',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  @override
  Future<List<Supplier>> getSuppliers({String? query}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query == null || query.isEmpty) return List.unmodifiable(_suppliers);

    final lowerQuery = query.toLowerCase();
    return _suppliers.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          (s.contactName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (s.phone?.contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _suppliers.add(supplier);
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index >= 0) {
      _suppliers[index] = supplier;
    } else {
      throw Exception('Supplier not found');
    }
  }
}
