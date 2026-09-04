import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';
import '../services/dictionary_service.dart';
import '../services/subscription_service.dart';
import '../services/overspend_service.dart';
import '../services/text_normalizer.dart';
import '../utils/period_helper.dart';
import 'package:provider/provider.dart';
import 'plan_provider.dart';
import '../widgets/overspend_bottom_sheet.dart';
import 'recent_widget_provider.dart';

class ExpenseProvider with ChangeNotifier {
  final HiveService _hiveService;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  List<SubscriptionInfo> _subscriptions = [];

  List<SubscriptionInfo> get subscriptions => _subscriptions;

  // --- Filter Existing ---
  String _selectedCategory = 'Semua Kategori';
  MonthFilter _selectedMonthFilter =
      MonthFilter.values[DateTime.now().month - 1];
  SortFilter _selectedSortFilter = SortFilter.newest;

  // --- Filter Baru (Custom Date, Price, Search) ---
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _searchQuery = '';

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
  String get searchQuery => _searchQuery;

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

  // --- Subscription Wrappers ---

  void toggleSubscription(SubscriptionInfo sub, bool isActive) {
    sub.isActive = isActive;
    SubscriptionService.saveToHive(_hiveService, _subscriptions);
    notifyListeners();
  }

  void saveSubscriptionData(String key, Map<String, dynamic> data) {
    _hiveService.saveSubscription(key, data);
    loadExpenses();
  }

  // --- CRUD ---

  void loadExpenses() {
    _expenses = _hiveService.getAllExpenses();
    _applyFilters();
    _detectSubscriptions();
    notifyListeners();
    _syncRecentWidget();
  }

  void _detectSubscriptions() {
    final detected = SubscriptionService.detectSubscriptions(_expenses);
    final saved = SubscriptionService.loadFromHive(_hiveService);
    final merged = <String, SubscriptionInfo>{};
    for (final s in saved) merged[s.key] = s;
    for (final d in detected) {
      if (!merged.containsKey(d.key)) {
        merged[d.key] = d;
      }
    }
    _subscriptions = merged.values.toList();
    SubscriptionService.saveToHive(_hiveService, _subscriptions);
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

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    if (start != null && end != null) {
      _selectedMonthFilter = MonthFilter.all;
    }
    _applyFilters();
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // --- CORE LOGIC: APPLY FILTERS ---

  void _applyFilters() {
    List<Expense> tempExpenses = _expenses;

    if (_startDate != null && _endDate != null) {
      tempExpenses = _filterByCustomDateRange(tempExpenses);
    } else {
      tempExpenses = _filterByMonth(tempExpenses);
    }

    tempExpenses = _filterByCategory(tempExpenses);
    tempExpenses = _filterBySearchQuery(tempExpenses);
    tempExpenses = _filterByPrice(tempExpenses);
    _filteredExpenses = _sortExpenses(tempExpenses);
  }

  List<Expense> _filterByCustomDateRange(List<Expense> expenses) {
    if (_startDate == null || _endDate == null) return expenses;
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    return expenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          expense.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<Expense> _filterBySearchQuery(List<Expense> expenses) {
    if (_searchQuery.isEmpty) return expenses;
    final query = _searchQuery.toLowerCase();
    return expenses.where((e) =>
      e.title.toLowerCase().contains(query) ||
      e.category.toLowerCase().contains(query)
    ).toList();
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
    if (_selectedMonthFilter == MonthFilter.all) return expenses;
    final monthIndex = _selectedMonthFilter.index + 1;
    final now = DateTime.now();
    final year = now.year;
    return expenses
        .where((expense) =>
            expense.date.year == year && expense.date.month == monthIndex)
        .toList();
  }

  List<Expense> _filterByCategory(List<Expense> expenses) {
    if (_selectedCategory == 'Semua Kategori') return expenses;
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
      case SortFilter.largest:
        return List.from(expenses)..sort((a, b) => b.amount.compareTo(a.amount));
      case SortFilter.smallest:
        return List.from(expenses)..sort((a, b) => a.amount.compareTo(b.amount));
    }
  }

  // --- Reset ---

  void resetFilters() {
    _selectedCategory = 'Semua Kategori';
    _selectedMonthFilter = MonthFilter.all;
    _selectedSortFilter = SortFilter.newest;
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  String _resolveTitle(String title) {
    if (title.isEmpty) return title;
    final existingTitles = _expenses.map((e) => e.title).toSet().toList();
    final match = findClosestMatch(title, existingTitles, threshold: 0.7);
    return match ?? title;
  }

  Future<void> addExpense(Expense expense, {String? sttCategory}) async {
    final resolvedTitle = _resolveTitle(expense.title);
    final updated = Expense(
      id: expense.id,
      title: resolvedTitle,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      type: expense.type,
    );
    _saveCorrectionIfNeeded(sttCategory, expense.category, resolvedTitle);
    await _hiveService.addExpense(updated);
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

  double checkShortfall(double amount, {int payDay = 1}) {
    final periodExpenses = _expenses
        .where((e) =>
            e.type == 'expense' &&
            e.category != 'Tabungan' &&
            PeriodHelper.isInPeriod(e.date, payDay))
        .fold(0.0, (sum, e) => sum + e.amount);
    final periodIncome = _expenses
        .where((e) =>
            e.type == 'income' &&
            e.category != 'Tabungan' &&
            PeriodHelper.isInPeriod(e.date, payDay))
        .fold(0.0, (sum, e) => sum + e.amount);
    final available = periodIncome - periodExpenses;
    if (amount > available) return amount - available;
    return 0;
  }

  /// Unified overspend handler: check shortfall → show bottom sheet → execute allocations.
  /// Returns true jika boleh lanjut, false jika user batal.
  Future<bool> handleOverspendIfNeeded({
    required double amount,
    required int payDay,
    required BuildContext context,
    required PlanProvider planProvider,
  }) async {
    final shortfall = checkShortfall(amount, payDay: payDay);
    if (shortfall <= 0) return true;

    final plans = planProvider.plans.where((p) => p.currentAmount > 0).toList();
    if (plans.isEmpty) return true;

    final totalPlansBalance =
        plans.fold<double>(0, (sum, p) => sum + p.currentAmount);

    final allocations = await showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OverspendBottomSheet(
        shortfall: shortfall,
        plans: plans,
        totalPlansBalance: totalPlansBalance,
      ),
    );

    if (allocations == null) return false;

    await OverspendService.executeAllocations(
      allocations: allocations,
      plans: planProvider.plans,
      expenseProvider: this,
      planProvider: planProvider,
    );
    return true;
  }

  void _saveCorrectionIfNeeded(String? sttCategory, String finalCategory, String title) {
    if (sttCategory == null || sttCategory == finalCategory) return;
    if (sttCategory == 'Lainnya' && finalCategory != 'Lainnya') {
      final word = title.split(' ').first;
      DictionaryService.instance.saveCorrection(word, finalCategory);
    }
  }

  Future<void> editExpense(Expense updatedExpense, {String? sttCategory}) async {
    final resolvedTitle = _resolveTitle(updatedExpense.title);
    final updated = Expense(
      id: updatedExpense.id,
      title: resolvedTitle,
      amount: updatedExpense.amount,
      date: updatedExpense.date,
      category: updatedExpense.category,
      type: updatedExpense.type,
    );
    _saveCorrectionIfNeeded(sttCategory, updatedExpense.category, resolvedTitle);
    await _hiveService.updateExpense(updated);
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
