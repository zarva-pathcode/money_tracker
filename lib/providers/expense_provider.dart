import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';
import '../utils/period_helper.dart';
import 'recent_widget_provider.dart';

class ExpenseProvider with ChangeNotifier {
  final HiveService _hiveService;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];

  // --- Filter Existing ---
  String _selectedCategory = 'Semua Kategori';
  MonthFilter _selectedMonthFilter =
      MonthFilter.values[DateTime.now().month - 1];
  SortFilter _selectedSortFilter = SortFilter.newest;

  // --- Filter Baru (Custom Date & Price) ---
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;

  // --- Getters ---
  List<Expense> get expenses => _filteredExpenses;
  List<Expense> get allExpenses => _expenses;

  String get selectedCategory => _selectedCategory;
  MonthFilter get selectedMonthFilter => _selectedMonthFilter;
  SortFilter get selectedSortFilter => _selectedSortFilter;

  // Getter Filter Baru
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;

  double get totalExpenses {
    return _filteredExpenses
        .where((e) => e.type == 'expense')
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalIncome {
    return _filteredExpenses
        .where((e) => e.type == 'income')
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get balance {
    return totalIncome - totalExpenses;
  }

  ExpenseProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    loadExpenses();
  }

  void loadExpenses() {
    _expenses = _hiveService.getAllExpenses();
    _applyFilters();
    notifyListeners();
    _syncRecentWidget();
  }

  void _syncRecentWidget() {
    final allTimeInc = _expenses
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);
    final allTimeExp = _expenses
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, e) => sum + e.amount);
    final allTimeBal = allTimeInc - allTimeExp;
    final recent = List<Expense>.from(_expenses.where((e) => e.type == 'expense'))
      ..sort((a, b) => b.date.compareTo(a.date));
    RecentWidgetProvider.sync(
      balance: allTimeBal,
      periodExpenses: balance,
      balanceLabel: _selectedMonthFilter == MonthFilter.all ? 'Total' : 'Bulan Ini',
      recentExpenses: recent.take(15).toList(),
    );
  }

  // --- Setters ---

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setMonthFilter(MonthFilter monthFilter) {
    _selectedMonthFilter = monthFilter;
    // Jika user memilih filter bulan spesifik, kita reset custom date range agar tidak bentrok
    if (monthFilter != MonthFilter.all) {
      _startDate = null;
      _endDate = null;
    }
    _applyFilters();
    notifyListeners();
  }

  void setSortFilter(SortFilter sortFilter) {
    _selectedSortFilter = sortFilter;
    _applyFilters();
    notifyListeners();
  }

  // Setter Filter Baru: Rentang Tanggal
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;

    // Jika custom date dipilih, kita set MonthFilter ke 'All' secara visual
    // agar logika tidak bentrok (Custom Date punya prioritas lebih tinggi)
    if (start != null && end != null) {
      _selectedMonthFilter = MonthFilter.all;
    }

    _applyFilters();
    notifyListeners();
  }

  // Setter Filter Baru: Rentang Harga
  void setPriceRange(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    _applyFilters();
    notifyListeners();
  }

  // --- CORE LOGIC: APPLY FILTERS ---

  void _applyFilters() {
    List<Expense> tempExpenses = _expenses;

    // 1. Filter Waktu (Prioritas: Custom Range > Month Filter)
    if (_startDate != null && _endDate != null) {
      tempExpenses = _filterByCustomDateRange(tempExpenses);
    } else {
      tempExpenses = _filterByMonth(tempExpenses);
    }

    // 2. Filter Kategori
    tempExpenses = _filterByCategory(tempExpenses);

    // 3. Filter Harga (Baru)
    tempExpenses = _filterByPrice(tempExpenses);

    // 4. Sorting
    _filteredExpenses = _sortExpenses(tempExpenses);
  }

  // --- Helper Filtering Methods ---

  List<Expense> _filterByCustomDateRange(List<Expense> expenses) {
    if (_startDate == null || _endDate == null) return expenses;

    // Normalisasi tanggal (set jam ke 00:00:00) agar akurat
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1)); // Sampai akhir hari

    return expenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          expense.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<Expense> _filterByPrice(List<Expense> expenses) {
    var result = expenses;
    if (_minAmount != null) {
      result = result.where((e) => e.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      result = result.where((e) => e.amount <= _maxAmount!).toList();
    }
    return result;
  }

  List<Expense> _filterByMonth(List<Expense> expenses) {
    if (_selectedMonthFilter == MonthFilter.all) {
      return expenses;
    }

    final monthIndex = _selectedMonthFilter.index + 1;
    final now = DateTime.now();
    final year = now.year;

    return expenses
        .where(
          (expense) =>
              expense.date.year == year && expense.date.month == monthIndex,
        )
        .toList();
  }

  List<Expense> _filterByCategory(List<Expense> expenses) {
    if (_selectedCategory == 'Semua Kategori') {
      return expenses;
    }
    return expenses
        .where((expense) => expense.category == _selectedCategory)
        .toList();
  }

  List<Expense> _sortExpenses(List<Expense> expenses) {
    switch (_selectedSortFilter) {
      case SortFilter.newest:
        return List.from(expenses)..sort((a, b) => b.date.compareTo(a.date));

      case SortFilter.oldest:
        return List.from(expenses)..sort((a, b) => a.date.compareTo(b.date));

      case SortFilter
          .largest: // Pastikan enum di Constants bernama 'highest' atau 'largest'
        return List.from(expenses)
          ..sort((a, b) => b.amount.compareTo(a.amount));

      case SortFilter
          .smallest: // Pastikan enum di Constants bernama 'lowest' atau 'smallest'
        return List.from(expenses)
          ..sort((a, b) => a.amount.compareTo(b.amount));
    }
  }

  // --- Reset Function ---

  void resetFilters() {
    _selectedCategory = 'Semua Kategori';
    _selectedMonthFilter = MonthFilter.all;
    _selectedSortFilter = SortFilter.newest;

    // Reset variable baru
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;

    _applyFilters();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _hiveService.addExpense(expense);
    loadExpenses();
  }

  Future<void> addSavingsAllocation({
    required double amount,
    required String planTitle,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      title: 'Tabungan: $planTitle',
      amount: amount,
      date: DateTime.now(),
      category: 'Tabungan',
      type: 'expense',
    );
    await addExpense(expense);
  }

  Future<void> withdrawSavingsAllocation({
    required double amount,
    required String planTitle,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      title: 'Penarikan: $planTitle',
      amount: amount,
      date: DateTime.now(),
      category: 'Tabungan',
      type: 'income',
    );
    await addExpense(expense);
  }

  /// Checks if adding an expense of [amount] would exceed the current period
  /// balance. Uses custom [payDay] cycle (default 1 = calendar month).
  /// Returns the shortfall if any, or 0 if balance is sufficient.
  double checkShortfall(double amount, {int payDay = 1}) {
    final periodExpenses = _expenses
        .where((e) =>
            e.type == 'expense' && PeriodHelper.isInPeriod(e.date, payDay))
        .fold(0.0, (sum, e) => sum + e.amount);
    final periodIncome = _expenses
        .where((e) =>
            e.type == 'income' && PeriodHelper.isInPeriod(e.date, payDay))
        .fold(0.0, (sum, e) => sum + e.amount);
    final available = periodIncome - periodExpenses;
    if (amount > available) {
      return amount - available;
    }
    return 0;
  }

  Future<void> editExpense(Expense updatedExpense) async {
    await _hiveService.updateExpense(updatedExpense);
    loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _hiveService.deleteExpense(id);
    loadExpenses();
  }

  Future<void> clearAllExpenses() async {
    await _hiveService.clearAllExpenses();
    loadExpenses();
  }
}
