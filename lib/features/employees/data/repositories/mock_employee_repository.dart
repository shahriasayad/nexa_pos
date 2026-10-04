import '../../domain/models/employee.dart';
import '../../domain/repositories/employee_repository.dart';

class MockEmployeeRepository implements EmployeeRepository {
  final List<Employee> _employees = [
    Employee(
      id: 'emp-1',
      name: 'Super Admin',
      email: 'admin@nexapos.com',
      role: EmployeeRole.admin,
      createdAt: DateTime.now(),
    ),
    Employee(
      id: 'emp-2',
      name: 'Store Manager',
      email: 'manager@nexapos.com',
      role: EmployeeRole.manager,
      createdAt: DateTime.now(),
    ),
    Employee(
      id: 'emp-3',
      name: 'John Cashier',
      email: 'john@nexapos.com',
      role: EmployeeRole.cashier,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Employee>> getEmployees({String? query}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query == null || query.isEmpty) return List.unmodifiable(_employees);
    
    final lower = query.toLowerCase();
    return _employees.where((e) => 
      e.name.toLowerCase().contains(lower) || 
      e.email.toLowerCase().contains(lower)
    ).toList();
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _employees.add(employee);
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee;
    } else {
      throw Exception('Employee not found');
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _employees.removeWhere((e) => e.id == id);
  }
}
