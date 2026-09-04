import 'package:flutter/material.dart';
import '../models/budget_item.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../utils/period_helper.dart';
import 'expense_provider.dart';

class CategoryAllowanceInfo {
  final String category;
  final double limitAmount;
  final double dailyAllowance;
  final double spentToday;
  final double remainingToday;
  final String granularity;

  CategoryAllowanceInfo({
    required this.category,
    required this.limitAmount,
    required this.dailyAllowance,
    required this.spentToday,
    required this.remainingToday,
    this.granularity = 'monthly',
  });

  double get progress => dailyAllowance > 0 ? (spentToday / dailyAllowance).clamp(0.0, 1.0) : 0.0;
  bool get isOver => spentToday > dailyAllowance;
}

class SmartDailyBudgetInfo {
  final double globalDailyAllowance;
  final double globalSpentToday;
  final double globalRemainingToday;
  final int remainingDays;
  final int totalDaysInPeriod;
  final List<CategoryAllowanceInfo> categories;

  SmartDailyBudgetInfo({
    required this.globalDailyAllowance,
    required this.globalSpentToday,
    required this.globalRemainingToday,
    required this.remainingDays,
    required this.totalDaysInPeriod,
    required this.categories,
  });

  double get progress => globalDailyAllowance > 0 ? (globalSpentToday / globalDailyAllowance).clamp(0.0, 1.0) : 0.0;
  bool get isOver => globalSpentToday > globalDailyAllowance;
}

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

  SmartDailyBudgetInfo getSmartDailyBudgetInfo(int payDay) {
    final now = DateTime.now();
    final start = PeriodHelper.getPeriodStart(payDay, now: now);
    final end = PeriodHelper.getPeriodEnd(payDay, now: now);

    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final totalDaysInPeriod = end.difference(start).inDays + 1;
    final remainingDays = end.difference(todayStart).inDays + 1;
    final safeRemainingDays = remainingDays < 1 ? 1 : remainingDays;

    final expenses = _expenseProvider?.allExpenses ?? [];

    double globalSpentBeforeToday = 0;
    double globalSpentToday = 0;

    List<CategoryAllowanceInfo> categoryInfos = [];

    for (final budget in _budgets) {
      double catSpentBeforeToday = 0;
      double catSpentToday = 0;

      for (final e in expenses) {
        if (e.type != 'expense') continue;
        if (e.category != budget.category) continue;

        if (e.date.isAfter(start.subtract(const Duration(seconds: 1))) && e.date.isBefore(todayStart)) {
          catSpentBeforeToday += e.amount;
        } else if (!e.date.isBefore(todayStart) && !e.date.isAfter(todayEnd)) {
          catSpentToday += e.amount;
        }
      }

      final catRemainingBudget = (budget.limitAmount - catSpentBeforeToday).clamp(0.0, double.infinity);
      
      double catAllowance = catRemainingBudget / safeRemainingDays;
      if (budget.granularity == 'weekly') {
        catAllowance = catRemainingBudget / (safeRemainingDays / 7.0);
      } else if (budget.granularity == 'monthly') {
        catAllowance = catRemainingBudget;
      }
      
      final catRemainingToday = catAllowance - catSpentToday;

      categoryInfos.add(CategoryAllowanceInfo(
        category: budget.category,
        limitAmount: budget.limitAmount,
        dailyAllowance: catAllowance,
        spentToday: catSpentToday,
        remainingToday: catRemainingToday,
        granularity: budget.granularity,
      ));

      globalSpentBeforeToday += catSpentBeforeToday;
      globalSpentToday += catSpentToday;
    }

    final globalLimit = totalBudget;
    final globalRemainingBudget = (globalLimit - globalSpentBeforeToday).clamp(0.0, double.infinity);
    final globalDailyAllowance = globalLimit > 0 ? globalRemainingBudget / safeRemainingDays : 0.0;
    final globalRemainingToday = globalDailyAllowance - globalSpentToday;

    return SmartDailyBudgetInfo(
      globalDailyAllowance: globalDailyAllowance,
      globalSpentToday: globalSpentToday,
      globalRemainingToday: globalRemainingToday,
      remainingDays: safeRemainingDays,
      totalDaysInPeriod: totalDaysInPeriod,
      categories: categoryInfos,
    );
  }

  BudgetProvider({
    required HiveService hiveService,
    required ExpenseProvider expenseProvider,
  }) : _hiveService = hiveService {
    _expenseProvider = expenseProvider;
    expenseProvider.addListener(checkAndNotify);
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

  void checkAndNotify() {
    notifyListeners(); // UI harus update dulu sebelum cek alert

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
