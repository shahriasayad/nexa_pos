import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../../../core/auth/auth_provider.dart';

class EmployeeController extends ChangeNotifier {
  final EmployeeRepository repository;

  EmployeeController({required this.repository});

  ViewState state = ViewState.initial;
  String? errorMessage;
  
  List<Employee> employees = [];
  String? currentQuery;

  Future<void> loadEmployees({String? query}) async {
    currentQuery = query;
    _setState(ViewState.loading);
    try {
      employees = await repository.getEmployees(query: query);
      _setState(employees.isEmpty ? ViewState.empty : ViewState.success);
    } catch (e) {
      errorMessage = e.toString();
      _setState(ViewState.error);
    }
  }

  Future<bool> saveEmployee(Employee employee) async {
    if (!AuthProvider.instance.can(Permission.manageEmployees)) {
      errorMessage = 'Permission denied: Cannot manage employees.';
      notifyListeners();
      return false;
    }
    
    try {
      final existing = await repository.getEmployeeById(employee.id);
      if (existing != null) {
        await repository.updateEmployee(employee);
      } else {
        await repository.saveEmployee(employee);
      }
      await loadEmployees(query: currentQuery);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    if (!AuthProvider.instance.can(Permission.manageEmployees)) {
      errorMessage = 'Permission denied: Cannot manage employees.';
      notifyListeners();
      return false;
    }
    
    try {
      await repository.deleteEmployee(id);
      await loadEmployees(query: currentQuery);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setState(ViewState newState) {
    state = newState;
    notifyListeners();
  }
}
