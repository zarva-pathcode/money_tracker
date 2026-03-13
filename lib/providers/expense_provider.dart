import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';

class ExpenseProvider with ChangeNotifier {
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

  ExpenseProvider() {
    loadExpenses();
  }

  void loadExpenses() {
    _expenses = HiveService.getAllExpenses();
    _applyFilters();
    notifyListeners();
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

  // --- Chart & Helpers (Tidak Berubah) ---

  Map<String, double> getWeeklyDataForMonth() {
    final monthData = <String, double>{};
    final selectedMonth = _selectedMonthFilter.index + 1;

    for (int week = 1; week <= 4; week++) {
      monthData['Minggu $week'] = 0.0;
    }

    for (var expense in _filteredExpenses) {
      // Logika minggu sederhana
      // Jika custom range aktif, tetap hitung berdasarkan data yang terfilter saja
      bool include = false;
      if (_startDate != null && _endDate != null) {
        include =
            true; // Karena _filteredExpenses sudah difilter di _applyFilters
      } else if (_selectedMonthFilter == MonthFilter.all ||
          expense.date.month == selectedMonth) {
        include = true;
      }

      if (include && expense.type == 'expense') {
        final week = ((expense.date.day - 1) ~/ 7) + 1;
        final weekKey = 'Minggu ${week.clamp(1, 4)}';
        monthData[weekKey] = (monthData[weekKey] ?? 0) + expense.amount;
      }
    }

    return monthData;
  }

  String getCurrentMonthYear() {
    // Jika menggunakan Custom Date Range
    if (_startDate != null && _endDate != null) {
      // Format sederhana: "1 Nov - 10 Nov"
      return "Filter Custom";
    }

    final now = DateTime.now();
    if (_selectedMonthFilter == MonthFilter.all) {
      return 'Semua Bulan ${now.year}';
    }

    final monthName = Constants.months[_selectedMonthFilter.index];
    return '$monthName ${now.year}';
  }

  Future<void> addExpense(Expense expense) async {
    await HiveService.addExpense(expense);
    loadExpenses();
  }

  Future<void> editExpense(Expense updatedExpense) async {
    await HiveService.updateExpense(updatedExpense);
    loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await HiveService.deleteExpense(id);
    loadExpenses();
  }

  Future<void> clearAllExpenses() async {
    await HiveService.clearAllExpenses();
    loadExpenses();
  }

  Map<String, double> getCategoryDataForChart() {
    final categoryData = <String, double>{};

    for (var expense in _filteredExpenses) {
      if (expense.type != 'expense') continue;
      
      if (categoryData.containsKey(expense.category)) {
        categoryData[expense.category] =
            categoryData[expense.category]! + expense.amount;
      } else {
        categoryData[expense.category] = expense.amount;
      }
    }

    return categoryData;
  }

  Map<String, double> getCategoryTotals() {
    Map<String, double> categoryTotals = {};

    for (var expense in _filteredExpenses) {
      if (expense.type != 'expense') continue;
      
      if (categoryTotals.containsKey(expense.category)) {
        categoryTotals[expense.category] =
            categoryTotals[expense.category]! + expense.amount;
      } else {
        categoryTotals[expense.category] = expense.amount;
      }
    }

    return categoryTotals;
  }

  // Di dalam class ExpenseProvider...

  // 1. Hitung Total Bulan Lalu (Untuk perbandingan)
  double getPreviousMonthTotal() {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);

    // Filter manual khusus untuk bulan lalu
    final lastMonthExpenses = _expenses.where(
      (e) =>
          e.type == 'expense' &&
          e.date.year == lastMonthDate.year &&
          e.date.month == lastMonthDate.month,
    );

    return lastMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  // 2. Hitung Rata-rata Harian (Bulan ini)
  double getDailyAverage() {
    if (totalExpenses == 0) return 0;

    // Jika filter bukan bulan ini, kita bagi dengan jumlah hari dalam bulan tersebut
    // Tapi untuk simpelnya, kita bagi dengan tanggal hari ini (running average)
    final now = DateTime.now();
    final day = now.day; // Tanggal hari ini (misal tgl 22)

    // Hindari pembagian 0
    if (day == 0) return 0;

    return totalExpenses / day;
  }

  // Di dalam class ExpenseProvider

  Color getCategoryColor(String category) {
    // Mengambil style dari Constants
    final style = Constants.getCategoryStyle(category);
    // Mengembalikan warnanya saja
    return style['color'] as Color;
  }
}
