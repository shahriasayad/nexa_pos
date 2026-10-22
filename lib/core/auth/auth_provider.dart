import 'package:flutter/material.dart';

import '../../features/employees/domain/models/employee.dart';
import '../../features/employees/domain/repositories/employee_repository.dart';
import '../repositories/app_repositories.dart';

class AuthProvider extends ChangeNotifier {
  static final AuthProvider instance = AuthProvider._internal();

  final EmployeeRepository repository = AppRepositories.instance.employeeRepo;
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

  Future<void> switchRole(EmployeeRole role) async {
    final emps = await repository.getEmployees();
    final match = emps.firstWhere(
      (e) => e.role == role,
      orElse: () => emps.first,
    );
    switchUser(match);
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
