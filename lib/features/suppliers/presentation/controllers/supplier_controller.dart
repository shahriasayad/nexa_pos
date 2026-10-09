import 'package:flutter/material.dart';

import '../../../../core/state/view_state.dart';
import '../../domain/models/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

class SupplierController extends ChangeNotifier {
  final SupplierRepository repository;

  SupplierController({required this.repository});

  ViewState state = ViewState.initial;
  String? errorMessage;

  List<Supplier> suppliers = [];
  String? currentQuery;

  Future<void> loadSuppliers({String? query}) async {
    currentQuery = query;
    _setState(ViewState.loading);
    try {
      suppliers = await repository.getSuppliers(query: query);
      _setState(suppliers.isEmpty ? ViewState.empty : ViewState.success);
    } catch (e) {
      errorMessage = e.toString();
      _setState(ViewState.error);
    }
  }

  Future<bool> saveSupplier(Supplier supplier) async {
    try {
      final existing = await repository.getSupplierById(supplier.id);
      if (existing != null) {
        await repository.updateSupplier(supplier);
      } else {
        await repository.saveSupplier(supplier);
      }
      await loadSuppliers(query: currentQuery);
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
