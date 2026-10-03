import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/features/expenses/domain/models/expense.dart';
import 'package:nexa_pos/features/expenses/data/repositories/mock_expense_repository.dart';
import 'package:nexa_pos/features/expenses/presentation/controllers/expense_controller.dart';

void main() {
  group('ExpenseController', () {
    late MockExpenseRepository repo;
    late ExpenseController controller;

    setUp(() {
      repo = MockExpenseRepository();
      controller = ExpenseController(repository: repo);
    });

    test('initial state is ViewState.initial', () {
      expect(controller.state, ViewState.initial);
    });

    test('loadExpenses fetches data and sets success', () async {
      await controller.loadExpenses();
      expect(controller.state, ViewState.success);
      expect(controller.expenses.isNotEmpty, true);
    });

    test('saveExpense adds new expense', () async {
      final expense = Expense(
        id: 'new',
        title: 'New Exp',
        amount: 50.0,
        category: ExpenseCategory.other,
        date: DateTime.now(),
      );

      final success = await controller.saveExpense(expense);
      expect(success, true);
      
      final saved = await repo.getExpenseById('new');
      expect(saved, isNotNull);
      expect(saved!.title, 'New Exp');
    });

    test('deleteExpense removes expense', () async {
      final success = await controller.deleteExpense('exp-1');
      expect(success, true);
      
      final deleted = await repo.getExpenseById('exp-1');
      expect(deleted, isNull);
    });
    
    test('totalExpenses calculates correctly', () async {
      await controller.loadExpenses();
      // exp-1 is 1200, exp-2 is 60
      expect(controller.totalExpenses, 1260.0);
    });
  });
}
