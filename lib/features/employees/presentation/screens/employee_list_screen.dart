import 'package:flutter/material.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/employee.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../controllers/employee_controller.dart';
import 'employee_form_screen.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  late EmployeeController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController(repository: MockEmployeeRepository());
    _controller.loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openEmployeeForm([Employee? employee]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (result == true) {
      _controller.loadEmployees(query: _searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Employees',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _openEmployeeForm(),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => _controller.loadEmployees(query: val),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.state == ViewState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.state == ViewState.error) {
                  return Center(
                    child: Text(
                      _controller.errorMessage ?? 'Error loading employees',
                    ),
                  );
                }
                if (_controller.state == ViewState.empty) {
                  return const Center(child: Text('No employees found.'));
                }

                return ListView.builder(
                  itemCount: _controller.employees.length,
                  itemBuilder: (context, index) {
                    final employee = _controller.employees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: employee.isActive
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.danger.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.person,
                            color: employee.isActive
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        title: Text(employee.name),
                        subtitle: Text(
                          '${employee.role.displayName} • ${employee.email}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openEmployeeForm(employee),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
