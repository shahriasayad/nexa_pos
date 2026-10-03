import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
  });
  Future<Expense?> getExpenseById(String id);
  Future<void> saveExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}
