import '../models/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees({String? query});
  Future<Employee?> getEmployeeById(String id);
  Future<void> saveEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
}
