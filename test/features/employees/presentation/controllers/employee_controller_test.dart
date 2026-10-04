import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/features/employees/domain/models/employee.dart';
import 'package:nexa_pos/features/employees/data/repositories/mock_employee_repository.dart';
import 'package:nexa_pos/features/employees/presentation/controllers/employee_controller.dart';
import 'package:nexa_pos/core/auth/auth_provider.dart';

void main() {
  group('EmployeeController', () {
    late MockEmployeeRepository repo;
    late EmployeeController controller;

    setUp(() {
      AuthProvider.instance.testLoginAdmin();
      repo = MockEmployeeRepository();
      controller = EmployeeController(repository: repo);
    });

    test('initial state is ViewState.initial', () {
      expect(controller.state, ViewState.initial);
    });

    test('loadEmployees fetches data and sets success', () async {
      await controller.loadEmployees();
      expect(controller.state, ViewState.success);
      expect(controller.employees.isNotEmpty, true);
    });

    test('saveEmployee adds new employee', () async {
      final emp = Employee(
        id: 'new',
        name: 'New Emp',
        email: 'new@test.com',
        role: EmployeeRole.cashier,
        createdAt: DateTime.now(),
      );

      final success = await controller.saveEmployee(emp);
      expect(success, true);
      
      final saved = await repo.getEmployeeById('new');
      expect(saved, isNotNull);
      expect(saved!.name, 'New Emp');
    });

    test('deleteEmployee removes employee', () async {
      final success = await controller.deleteEmployee('emp-1');
      expect(success, true);
      
      final deleted = await repo.getEmployeeById('emp-1');
      expect(deleted, isNull);
    });
    
    test('saveEmployee fails if no permission', () async {
      AuthProvider.instance.switchUser(
        Employee(
          id: 'test-cashier',
          name: 'Test Cashier',
          email: 'test@cashier.com',
          role: EmployeeRole.cashier,
          createdAt: DateTime.now(),
        )
      );
      
      final emp = Employee(
        id: 'new2',
        name: 'New Emp2',
        email: 'new2@test.com',
        role: EmployeeRole.cashier,
        createdAt: DateTime.now(),
      );

      final success = await controller.saveEmployee(emp);
      expect(success, false);
      expect(controller.errorMessage, contains('Permission denied'));
    });
  });
}
