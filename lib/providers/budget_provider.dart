import 'package:flutter/material.dart';
import '../models/budget_item.dart';
import '../services/hive_service.dart';

class BudgetProvider with ChangeNotifier {
  final HiveService _hiveService;
  List<BudgetItem> _budgets = [];

  List<BudgetItem> get budgets => _budgets;

  BudgetProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    _loadBudgets();
  }

  void _loadBudgets() {
    _budgets = _hiveService.getAllBudgets();
    notifyListeners();
  }

  Future<void> addBudget(BudgetItem item) async {
    await _hiveService.addBudget(item);
    _loadBudgets();
  }

  Future<void> updateBudget(BudgetItem item) async {
    await _hiveService.updateBudget(item);
    _loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _hiveService.deleteBudget(id);
    _loadBudgets();
  }
}
