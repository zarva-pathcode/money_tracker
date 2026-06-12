import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../utils/period_helper.dart';
import 'expense_provider.dart';

class AnalysisProvider with ChangeNotifier {
  final ExpenseProvider _expenseProvider;

  AnalysisProvider({required ExpenseProvider expenseProvider})
      : _expenseProvider = expenseProvider {
    expenseProvider.addListener(notifyListeners);
  }

  List<Expense> get _all => _expenseProvider.allExpenses;
  List<Expense> get _filtered => _expenseProvider.expenses;

  // --- All-time getters (tidak terpengaruh filter) ---

  double get allTimeIncome {
    return _all
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get allTimeExpenses {
    return _all
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get allTimeBalance {
    return allTimeIncome - allTimeExpenses;
  }

  double get totalSavingsAllTime {
    return _all
        .where((e) => e.category == 'Tabungan')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalSavings {
    return _filtered
        .where((e) => e.category == 'Tabungan')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalNonSavingsExpenses {
    return _filtered
        .where((e) => e.type == 'expense' && e.category != 'Tabungan')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // --- Period-based getters (custom pay cycle) ---

  double getPeriodIncome(int payDay) {
    return _all
        .where((e) => e.type == 'income' && PeriodHelper.isInPeriod(e.date, payDay))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getPeriodExpenses(int payDay) {
    return _all
        .where((e) => e.type == 'expense' && PeriodHelper.isInPeriod(e.date, payDay))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getPeriodBalance(int payDay) => getPeriodIncome(payDay) - getPeriodExpenses(payDay);

  Map<String, double> getRunningBalances() {
    final sorted = List<Expense>.from(_all)
      ..sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

    double running = 0;
    final map = <String, double>{};
    for (final e in sorted) {
      running += e.type == 'income' ? e.amount : -e.amount;
      map[e.id] = running;
    }
    return map;
  }

  // --- Income helpers ---

  double get filteredIncome {
    return _filtered
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getIncomeCategoryDataForChart({
    bool includeWithdrawals = false,
  }) {
    final data = <String, double>{};
    for (var e in _filtered) {
      if (e.type != 'income') continue;
      if (!includeWithdrawals && e.category == 'Tabungan') continue;
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }
    return data;
  }

  Map<String, double> getIncomeCategoryTotals({
    bool includeWithdrawals = false,
  }) {
    final totals = <String, double>{};
    for (var e in _filtered) {
      if (e.type != 'income') continue;
      if (!includeWithdrawals && e.category == 'Tabungan') continue;
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  double getPreviousMonthIncome() {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    return _all
        .where((e) =>
            e.type == 'income' &&
            e.date.year == lastMonthDate.year &&
            e.date.month == lastMonthDate.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // --- Chart helpers ---

  Map<String, double> getWeeklyDataForMonth() {
    final monthData = <String, double>{};
    for (int week = 1; week <= 4; week++) {
      monthData['Minggu $week'] = 0.0;
    }

    for (var expense in _filtered) {
      if (expense.type == 'expense') {
        final week = ((expense.date.day - 1) ~/ 7) + 1;
        final weekKey = 'Minggu ${week.clamp(1, 4)}';
        monthData[weekKey] = (monthData[weekKey] ?? 0) + expense.amount;
      }
    }

    return monthData;
  }

  Map<String, double> getCategoryDataForChart({bool includeSavings = false}) {
    final categoryData = <String, double>{};
    for (var expense in _filtered) {
      if (expense.type != 'expense') continue;
      if (!includeSavings && expense.category == 'Tabungan') continue;
      categoryData[expense.category] =
          (categoryData[expense.category] ?? 0) + expense.amount;
    }
    return categoryData;
  }

  Map<String, double> getCategoryTotals({bool includeSavings = false}) {
    final categoryTotals = <String, double>{};
    for (var expense in _filtered) {
      if (expense.type != 'expense') continue;
      if (!includeSavings && expense.category == 'Tabungan') continue;
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Map<int, double> getMonthlyExpenseTotals(int year) {
    final data = <int, double>{};
    for (int i = 1; i <= 12; i++) data[i] = 0.0;
    for (var e in _all) {
      if (e.date.year == year && e.type == 'expense') {
        data[e.date.month] = (data[e.date.month] ?? 0) + e.amount;
      }
    }
    return data;
  }

  Map<int, double> getMonthlyIncomeTotals(int year) {
    final data = <int, double>{};
    for (int i = 1; i <= 12; i++) data[i] = 0.0;
    for (var e in _all) {
      if (e.date.year == year && e.type == 'income') {
        data[e.date.month] = (data[e.date.month] ?? 0) + e.amount;
      }
    }
    return data;
  }

  static const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _timeSlots = ['Pagi', 'Siang', 'Sore', 'Malam'];

  static String _timeSlot(int hour) {
    if (hour >= 6 && hour < 12) return 'Pagi';
    if (hour >= 12 && hour < 17) return 'Siang';
    if (hour >= 17 && hour < 19) return 'Sore';
    return 'Malam';
  }

  /// Return heatmap data: {dayName: {timeSlot: totalAmount}}
  Map<String, Map<String, double>> getTimeHeatmap() {
    final heatmap = <String, Map<String, double>>{};
    for (final day in _dayNames) {
      heatmap[day] = {for (final t in _timeSlots) t: 0.0};
    }
    for (final e in _filtered) {
      if (e.type != 'expense') continue;
      final day = _dayNames[e.date.weekday - 1];
      final slot = _timeSlot(e.date.hour);
      heatmap[day]![slot] = (heatmap[day]![slot] ?? 0) + e.amount;
    }
    return heatmap;
  }

  double get maxHeatmapValue {
    final hm = getTimeHeatmap();
    double max = 0;
    for (final day in hm.values) {
      for (final v in day.values) {
        if (v > max) max = v;
      }
    }
    return max;
  }

  List<String> get heatmapDayLabels => _dayNames;
  List<String> get heatmapTimeSlotLabels => _timeSlots;

  // --- Top transaction helpers ---

  List<Expense> getTopExpenseTransactions(int count) {
    final sorted = List<Expense>.from(
      _filtered.where((e) => e.type == 'expense'),
    )..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(count).toList();
  }

  List<Expense> getTopIncomeTransactions(int count) {
    final sorted = List<Expense>.from(
      _filtered.where((e) => e.type == 'income'),
    )..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(count).toList();
  }

  // --- Date/period helpers ---

  String get currentMonthYear {
    final hasCustom = _expenseProvider.startDate != null && _expenseProvider.endDate != null;
    if (hasCustom) return "Filter Custom";
    final now = DateTime.now();
    if (_expenseProvider.selectedMonthFilter == MonthFilter.all) {
      return 'Semua Bulan ${now.year}';
    }
    final monthName = Constants.months[_expenseProvider.selectedMonthFilter.index];
    return '$monthName ${now.year}';
  }

  double get previousMonthTotal {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    return _all
        .where((e) =>
            e.type == 'expense' &&
            e.date.year == lastMonthDate.year &&
            e.date.month == lastMonthDate.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get dailyAverage {
    final total = _expenseProvider.totalExpenses;
    if (total == 0) return 0;
    final day = DateTime.now().day;
    if (day == 0) return 0;
    return total / day;
  }
}
