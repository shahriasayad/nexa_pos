import 'package:flutter/material.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/state/view_state.dart';
import '../../data/repositories/mock_supplier_repository.dart';
import '../controllers/supplier_controller.dart';
import 'supplier_form_screen.dart';

import 'package:nexa_pos/core/theme/app_colors.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late SupplierController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SupplierController(repository: MockSupplierRepository());
    _controller.loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openSupplierForm([String? id]) async {
    final supplier = id != null
        ? _controller.suppliers.firstWhere((s) => s.id == id)
        : null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
    );
    if (result == true) {
      _controller.loadSuppliers(query: _searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Suppliers',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _openSupplierForm(),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => _controller.loadSuppliers(query: val),
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
                      _controller.errorMessage ?? 'Error loading suppliers',
                    ),
                  );
                }
                if (_controller.state == ViewState.empty) {
                  return const Center(child: Text('No suppliers found.'));
                }

                return ListView.builder(
                  itemCount: _controller.suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = _controller.suppliers[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.business)),
                      title: Text(supplier.name),
                      subtitle: Text(
                        supplier.contactName ??
                            supplier.email ??
                            'No contact info',
                      ),
                      trailing: Text(
                        supplier.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: supplier.isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      onTap: () => _openSupplierForm(supplier.id),
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
