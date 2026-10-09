import 'package:flutter/material.dart';

import '../../features/employees/domain/models/employee.dart';
import '../../features/employees/domain/repositories/employee_repository.dart';
import '../../features/employees/data/repositories/mock_employee_repository.dart';

class AuthProvider extends ChangeNotifier {
  static final AuthProvider instance = AuthProvider._internal();

  final EmployeeRepository repository = MockEmployeeRepository();
  Employee? _currentUser;

  AuthProvider._internal() {
    _init();
  }

  Future<void> _init() async {
    final emps = await repository.getEmployees();
    if (emps.isNotEmpty) {
      _currentUser = emps.first;
      notifyListeners();
    }
  }

  Employee? get currentUser => _currentUser;

  bool can(Permission p) => _currentUser?.hasPermission(p) ?? false;

  void switchUser(Employee emp) {
    _currentUser = emp;
    notifyListeners();
  }

  // Used for tests to ensure permissions pass synchronously
  void testLoginAdmin() {
    _currentUser = Employee(
      id: 'test-admin',
      name: 'Test Admin',
      email: 'test@admin.com',
      role: EmployeeRole.admin,
      createdAt: DateTime.now(),
    );
  }
}
