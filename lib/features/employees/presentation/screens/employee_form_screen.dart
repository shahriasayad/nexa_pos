import 'package:flutter/material.dart';
import '../../domain/models/employee.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../controllers/employee_controller.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late EmployeeController _controller;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  late EmployeeRole _role;
  bool _isActive = true;
  Set<Permission> _customPermissions = {};

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController(repository: MockEmployeeRepository());
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _emailController = TextEditingController(text: widget.employee?.email ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _role = widget.employee?.role ?? EmployeeRole.cashier;
    _isActive = widget.employee?.isActive ?? true;
    _customPermissions = widget.employee?.customPermissions ?? {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final employee = Employee(
        id: widget.employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        role: _role,
        isActive: _isActive,
        customPermissions: _customPermissions,
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
      );

      final success = await _controller.saveEmployee(employee);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.errorMessage ?? 'Failed to save employee')),
        );
      }
    }
  }

  void _delete() async {
    if (widget.employee == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final success = await _controller.deleteEmployee(widget.employee!.id);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
        actions: [
          if (widget.employee != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EmployeeRole>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: EmployeeRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _role = val;
                      _customPermissions.clear(); // Reset custom permissions when role changes
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active Status'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const Divider(height: 32),
              const Text('Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('By default, roles have preset permissions. Check or uncheck to create custom permissions for this user.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              ...Permission.values.map((perm) {
                final hasPerm = _customPermissions.isNotEmpty 
                  ? _customPermissions.contains(perm)
                  : _role.defaultPermissions.contains(perm);
                
                return CheckboxListTile(
                  title: Text(perm.name),
                  value: hasPerm,
                  onChanged: (val) {
                    setState(() {
                      if (_customPermissions.isEmpty) {
                        _customPermissions = Set.from(_role.defaultPermissions);
                      }
                      if (val == true) {
                        _customPermissions.add(perm);
                      } else {
                        _customPermissions.remove(perm);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Employee'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
