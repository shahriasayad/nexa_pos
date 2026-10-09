import 'package:flutter/material.dart';

import '../../../../core/state/view_state.dart';
import '../../domain/models/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerController extends ChangeNotifier {
  final CustomerRepository repository;

  CustomerController({required this.repository});

  ViewState state = ViewState.initial;
  List<Customer> customers = [];
  String? errorMessage;

  Future<void> loadCustomers({String? query}) async {
    state = ViewState.loading;
    notifyListeners();

    try {
      customers = await repository.getCustomers(searchQuery: query);
      state = customers.isEmpty ? ViewState.empty : ViewState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = ViewState.error;
    }
    notifyListeners();
  }

  Future<bool> saveCustomer(Customer customer) async {
    state = ViewState.loading;
    notifyListeners();
    try {
      final existing = await repository.getCustomerById(customer.id);
      if (existing != null) {
        await repository.updateCustomer(customer);
      } else {
        await repository.addCustomer(customer);
      }
      await loadCustomers();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      state = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await repository.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      errorMessage = e.toString();
      state = ViewState.error;
      notifyListeners();
    }
  }
}
