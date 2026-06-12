import 'package:flutter/material.dart';
import '../models/budget_item.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import 'expense_provider.dart';

class BudgetProvider with ChangeNotifier {
  final HiveService _hiveService;
  List<BudgetItem> _budgets = [];
  ExpenseProvider? _expenseProvider;

  List<BudgetItem> get budgets => _budgets;

  // --- Aggregation Getters ---

  double get totalBudget =>
      _budgets.fold<double>(0, (sum, b) => sum + b.limitAmount);

  double get totalSpent {
    final now = DateTime.now();
    final exps = _expenseProvider?.allExpenses ?? [];
    double total = 0;
    for (final budget in _budgets) {
      total += _getCategorySpending(exps, budget.category, now.month, now.year);
    }
    return total;
  }

  double get overallProgress =>
      totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

  double spentForCategory(String category) {
    final now = DateTime.now();
    final exps = _expenseProvider?.allExpenses ?? [];
    return _getCategorySpending(exps, category, now.month, now.year);
  }

  BudgetProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    _loadBudgets();
  }

  void linkToExpenseProvider(ExpenseProvider provider) {
    _expenseProvider = provider;
    provider.addListener(checkAndNotify);
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

  void checkAndNotify() {
    final enabled = _hiveService.getSetting('budget_alerts_enabled', true);
    if (!enabled) return;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final expenses = _expenseProvider?.allExpenses ?? [];

    for (int i = 0; i < _budgets.length; i++) {
      final budget = _budgets[i];
      final spent = _getCategorySpending(expenses, budget.category, currentMonth, currentYear);
      final pct = budget.limitAmount > 0 ? (spent / budget.limitAmount) * 100 : 0.0;
      final lastNotified = _hiveService.getSetting('budget_alert_${budget.category}', 0.0);

      final thresholdPct = budget.threshold;
      var notifyAt = <double>[];

      if (thresholdPct < 100) {
        notifyAt = [thresholdPct, 100.0, 120.0];
      } else {
        notifyAt = [100.0, 120.0];
      }

      for (final level in notifyAt) {
        if (pct >= level && lastNotified < level) {
          _sendBudgetNotification(i, budget.category, spent, budget.limitAmount, level);
          _hiveService.setSetting('budget_alert_${budget.category}', level);
          break;
        }
      }

      if (pct < thresholdPct) {
        _hiveService.setSetting('budget_alert_${budget.category}', 0.0);
      }
    }
  }

  double _getCategorySpending(List<Expense> expenses, String category, int month, int year) {
    double total = 0;
    for (final e in expenses) {
      if (e.category == category &&
          e.date.month == month &&
          e.date.year == year &&
          e.type == 'expense') {
        total += e.amount;
      }
    }
    return total;
  }

  void _sendBudgetNotification(int index, String category, double spent, double limit, double level) {
    String title;
    String body;

    if (level >= 120) {
      title = 'Anggaran $category Jebol!';
      body = 'Pengeluaran ${spent.toStringAsFixed(0)} dari ${limit.toStringAsFixed(0)} (${level.toStringAsFixed(0)}%). Segera evaluasi!';
    } else if (level >= 100) {
      title = 'Anggaran $category Habis';
      body = 'Kamu sudah menghabiskan seluruh anggaran $category bulan ini (${spent.toStringAsFixed(0)} dari ${limit.toStringAsFixed(0)}).';
    } else {
      title = 'Anggaran $category Hampir Habis';
      body = 'Pengeluaran sudah mencapai ${level.toStringAsFixed(0)}% dari limit. Bijaklah dalam berbelanja!';
    }

    NotificationService.showBudgetAlert(
      id: 200 + index,
      title: title,
      body: body,
    );
  }
}
