import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/features/suppliers/domain/models/supplier.dart';
import 'package:nexa_pos/features/suppliers/data/repositories/mock_supplier_repository.dart';
import 'package:nexa_pos/features/suppliers/presentation/controllers/supplier_controller.dart';

void main() {
  group('SupplierController', () {
    late MockSupplierRepository repo;
    late SupplierController controller;

    setUp(() {
      repo = MockSupplierRepository();
      controller = SupplierController(repository: repo);
    });

    test('initial state is ViewState.initial', () {
      expect(controller.state, ViewState.initial);
    });

    test('loadSuppliers fetches data and sets success', () async {
      await controller.loadSuppliers();
      expect(controller.state, ViewState.success);
      expect(controller.suppliers.isNotEmpty, true);
    });

    test('saveSupplier adds new supplier', () async {
      final supplier = Supplier(
        id: 'new',
        name: 'New Sup',
        createdAt: DateTime.now(),
      );

      final success = await controller.saveSupplier(supplier);
      expect(success, true);
      
      final saved = await repo.getSupplierById('new');
      expect(saved, isNotNull);
      expect(saved!.name, 'New Sup');
    });
  });
}
