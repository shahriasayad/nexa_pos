import '../models/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getSuppliers({String? query});
  Future<Supplier?> getSupplierById(String id);
  Future<void> saveSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
}
