import 'package:flutter/material.dart';

import '../../../../core/state/view_state.dart';
import '../../../customers/data/repositories/mock_customer_repository.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';

class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  late CustomerController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CustomerController(repository: MockCustomerRepository());
    _controller.loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Customer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => _controller.loadCustomers(query: val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.state == ViewState.loading ||
                      _controller.state == ViewState.initial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_controller.state == ViewState.error) {
                    return Center(
                      child: Text(_controller.errorMessage ?? 'Error'),
                    );
                  }
                  if (_controller.state == ViewState.empty) {
                    return const Center(child: Text('No customers found'));
                  }
                  return ListView.builder(
                    itemCount: _controller.customers.length,
                    itemBuilder: (context, index) {
                      final customer = _controller.customers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(customer.name),
                        subtitle: Text(customer.phone ?? customer.email ?? ''),
                        onTap: () {
                          Navigator.pop(context, customer);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null), // Cancel or walk-in doesn't matter here, cancel returns null but doesn't change selection
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    'clear',
                  ), // Special signal to clear customer
                  child: const Text('Walk-in Customer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
