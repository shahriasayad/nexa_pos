import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/features/customers/domain/models/customer.dart';
import 'package:nexa_pos/features/customers/data/repositories/mock_customer_repository.dart';
import 'package:nexa_pos/features/customers/presentation/controllers/customer_controller.dart';

void main() {
  group('CustomerController', () {
    late MockCustomerRepository repo;
    late CustomerController controller;

    setUp(() {
      repo = MockCustomerRepository();
      controller = CustomerController(repository: repo);
    });

    test('initial state is ViewState.initial', () {
      expect(controller.state, ViewState.initial);
    });

    test('loadCustomers loads data and sets state', () async {
      await controller.loadCustomers();
      expect(controller.state, ViewState.success);
      expect(controller.customers.isNotEmpty, true);
    });

    test('loadCustomers filters by query', () async {
      await controller.loadCustomers(query: 'john');
      expect(controller.state, ViewState.success);
      expect(controller.customers.length, 1);
      expect(controller.customers.first.name, 'John Doe');
    });

    test('saveCustomer adds new customer', () async {
      final customer = Customer(
        id: 'new',
        name: 'New Customer',
        createdAt: DateTime.now(),
      );

      final success = await controller.saveCustomer(customer);
      expect(success, true);
      
      final saved = await repo.getCustomerById('new');
      expect(saved, isNotNull);
      expect(saved!.name, 'New Customer');
    });

    test('saveCustomer updates existing customer', () async {
      await controller.loadCustomers();
      final customer = controller.customers.first;
      
      final updated = customer.copyWith(name: 'Updated Name');
      final success = await controller.saveCustomer(updated);
      expect(success, true);
      
      final saved = await repo.getCustomerById(customer.id);
      expect(saved!.name, 'Updated Name');
    });
  });
}
