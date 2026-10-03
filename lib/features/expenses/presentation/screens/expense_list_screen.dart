import 'package:flutter/material.dart';
import '../../../../core/layout/app_drawer.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/models/expense.dart';
import '../../data/repositories/mock_expense_repository.dart';
import '../controllers/expense_controller.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late ExpenseController _controller;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = ExpenseController(repository: MockExpenseRepository());
    _controller.loadExpenses();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openExpenseForm([Expense? expense]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
    if (result == true) {
      _controller.loadExpenses(category: _selectedCategory);
    }
  }

  void _onCategoryChanged(ExpenseCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _controller.loadExpenses(category: category);
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent: return Icons.home;
      case ExpenseCategory.electricity: return Icons.electric_bolt;
      case ExpenseCategory.internet: return Icons.wifi;
      case ExpenseCategory.salary: return Icons.attach_money;
      case ExpenseCategory.transportation: return Icons.directions_car;
      case ExpenseCategory.maintenance: return Icons.build;
      case ExpenseCategory.other: return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openExpenseForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (val) {
                      if (val) _onCategoryChanged(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...ExpenseCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(cat.displayName),
                        selected: _selectedCategory == cat,
                        onSelected: (val) {
                          _onCategoryChanged(val ? cat : null);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Text(
                  'Total: \$${_controller.totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
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
                  return Center(child: Text(_controller.errorMessage ?? 'Error loading expenses'));
                }
                if (_controller.state == ViewState.empty) {
                  return const Center(child: Text('No expenses found for this filter.'));
                }

                return ListView.builder(
                  itemCount: _controller.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _controller.expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          child: Icon(_getCategoryIcon(expense.category), color: Theme.of(context).primaryColor),
                        ),
                        title: Text(expense.title),
                        subtitle: Text('${expense.date.toString().split(' ')[0]} - ${expense.category.displayName}'),
                        trailing: Text(
                          '-\$${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () => _openExpenseForm(expense),
                      ),
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
