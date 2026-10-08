import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/customer.dart';
import '../../data/repositories/mock_customer_repository.dart';
import '../controllers/customer_controller.dart';
import 'customer_form_screen.dart';
import '../../../../core/layout/app_shell.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
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

  void _openCustomerForm([Customer? customer]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerFormScreen(
        customer: customer,
        controller: _controller,
      )),
    );
    if (result == true) {
      _controller.loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      
      title: 'Customers',
      actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openCustomerForm(),
          )
        ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _controller.loadCustomers();
                  },
                ),
              ),
              onChanged: (val) => _controller.loadCustomers(query: val),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return Center(child: Text(_controller.errorMessage ?? 'Error'));
      case ViewState.empty:
        return const Center(child: Text('No customers found'));
      case ViewState.success:
        return ListView.builder(
          itemCount: _controller.customers.length,
          itemBuilder: (context, index) {
            final customer = _controller.customers[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(customer.name),
              subtitle: Text(customer.phone ?? customer.email ?? 'No contact info'),
              trailing: Text('\$${customer.totalSpending.toStringAsFixed(2)}'),
              onTap: () => _openCustomerForm(customer),
            );
          },
        );
    }
  }
}
