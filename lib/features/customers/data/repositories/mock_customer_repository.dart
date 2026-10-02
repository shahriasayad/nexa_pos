import '../../domain/models/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  final List<Customer> _customers = [];

  MockCustomerRepository() {
    _customers.add(
      Customer(
        id: 'CUST-001',
        name: 'John Doe',
        phone: '123-456-7890',
        email: 'john@example.com',
        totalSpending: 250.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      )
    );
    _customers.add(
      Customer(
        id: 'CUST-002',
        name: 'Jane Smith',
        phone: '987-654-3210',
        totalSpending: 50.0,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      )
    );
  }

  @override
  Future<List<Customer>> getCustomers({String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (searchQuery == null || searchQuery.isEmpty) {
      return List.unmodifiable(_customers);
    }
    
    final query = searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
             (c.phone?.contains(query) ?? false) ||
             (c.email?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _customers.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _customers.add(customer);
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
    } else {
      throw Exception('Customer not found');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _customers.removeWhere((c) => c.id == id);
  }
}
