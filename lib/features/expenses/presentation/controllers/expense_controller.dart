import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseController extends ChangeNotifier {
  final ExpenseRepository repository;

  ExpenseController({required this.repository});

  ViewState state = ViewState.initial;
  String? errorMessage;
  
  List<Expense> expenses = [];
  ExpenseCategory? currentCategory;
  DateTime? currentStartDate;
  DateTime? currentEndDate;

  double get totalExpenses => expenses.fold(0, (sum, exp) => sum + exp.amount);

  Future<void> loadExpenses({
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    currentCategory = category;
    currentStartDate = startDate;
    currentEndDate = endDate;
    
    _setState(ViewState.loading);
    try {
      expenses = await repository.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      _setState(expenses.isEmpty ? ViewState.empty : ViewState.success);
    } catch (e) {
      errorMessage = e.toString();
      _setState(ViewState.error);
    }
  }

  Future<bool> saveExpense(Expense expense) async {
    try {
      final existing = await repository.getExpenseById(expense.id);
      if (existing != null) {
        await repository.updateExpense(expense);
      } else {
        await repository.saveExpense(expense);
      }
      await loadExpenses(
        category: currentCategory,
        startDate: currentStartDate,
        endDate: currentEndDate,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await repository.deleteExpense(id);
      await loadExpenses(
        category: currentCategory,
        startDate: currentStartDate,
        endDate: currentEndDate,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearFilters() {
    loadExpenses();
  }

  void _setState(ViewState newState) {
    state = newState;
    notifyListeners();
  }
}
