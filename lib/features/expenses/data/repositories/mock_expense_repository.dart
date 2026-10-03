import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [
    Expense(
      id: 'exp-1',
      title: 'Monthly Rent',
      amount: 1200.0,
      category: ExpenseCategory.rent,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Expense(
      id: 'exp-2',
      title: 'Internet Bill',
      amount: 60.0,
      category: ExpenseCategory.internet,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = _expenses.toList();

    if (startDate != null) {
      results = results.where((e) => e.date.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
    }
    if (endDate != null) {
      results = results.where((e) => e.date.isBefore(endDate.add(const Duration(seconds: 1)))).toList();
    }
    if (category != null) {
      results = results.where((e) => e.category == category).toList();
    }

    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses.add(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
    } else {
      throw Exception('Expense not found');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses.removeWhere((e) => e.id == id);
  }
}
