import 'package:flutter/material.dart';
import '../models/budget_item.dart';
import '../services/hive_service.dart';

class BudgetProvider with ChangeNotifier {
  List<BudgetItem> _budgets = [];

  List<BudgetItem> get budgets => _budgets;

  BudgetProvider() {
    _loadBudgets();
  }

  void _loadBudgets() {
    _budgets = HiveService.getAllBudgets();
    notifyListeners();
  }

  Future<void> addBudget(BudgetItem item) async {
    await HiveService.addBudget(item);
    _loadBudgets();
  }

  Future<void> updateBudget(BudgetItem item) async {
    await HiveService.updateBudget(item);
    _loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await HiveService.deleteBudget(id);
    _loadBudgets();
  }

  // Calculate spent amount based on expenses in ExpenseProvider
  // This will be used in the UI side
}
