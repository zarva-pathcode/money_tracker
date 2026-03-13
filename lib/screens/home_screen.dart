import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/models/chart_data.dart';
import 'package:money_tracker/models/expense.dart';
import 'package:money_tracker/screens/edit_expense_screen.dart';
import 'package:money_tracker/utils/constants.dart';
import 'package:money_tracker/widgets/category_breakdown.dart';
import 'package:money_tracker/widgets/expense_chart.dart';
import 'package:money_tracker/widgets/filter_bottom_sheet.dart';
import 'package:money_tracker/widgets/month_filter_selector.dart';
import 'package:money_tracker/widgets/month_picker_button.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/animated_tap.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              final chartData = _prepareChartData(expenseProvider);
              final hasActiveFilter =
                  expenseProvider.selectedCategory != 'Semua Kategori' ||
                  expenseProvider.selectedMonthFilter != MonthFilter.all ||
                  expenseProvider.startDate != null; // Cek juga custom date

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Header Mewah (SliverAppBar)
                  SliverAppBar(
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    backgroundColor: const Color(0xFFF5F7FA),
                    expandedHeight: 70.0,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    centerTitle: false,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                      title: Text(
                        'Ringkasan',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 20, // Ukuran font judul saat collapsed
                        ),
                      ),
                    ),
                    actions: [
                      // if (hasActiveFilter)
                      //   Container(
                      //     margin: const EdgeInsets.only(right: 8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.red.withOpacity(0.1),
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: IconButton(
                      //       icon: const Icon(
                      //         Icons.filter_alt_off,
                      //         color: Colors.redAccent,
                      //       ),
                      //       onPressed: () => expenseProvider.resetFilters(),
                      //       tooltip: 'Reset Filter',
                      //     ),
                      //   ),
                      // // Reset Filter ditiadakan sementara
                      // const SizedBox(width: 8),
                    ],
                  ),

                  // 2. Hero Section (Kartu Total Pengeluaran)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        children: [
                          _buildHeroCard(expenseProvider),
                          const SizedBox(height: 20),
                          // Perhatikan: chartData ini otomatis berubah saat badge diklik
                          _buildChartSection(expenseProvider, chartData),
                        ],
                      ),
                    ),
                  ),

                  // 4. Sticky Filter Bar
                  // 3. STICKY HEADER (Filter Icon + Month Badges)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyFilterDelegate(
                      minHeight: 60.0,
                      maxHeight: 60.0,
                      child: Container(
                        color: const Color(0xFFF5F7FA),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // A. Tombol Filter Lanjutan
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: 'Filter Lanjutan',
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (context) => const FilterBottomSheet(),
                                  );
                                },
                              ),
                            ),

                            // B. Garis Pemisah
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade300,
                            ),

                            // C. Badge Bulan (Widget Baru yang Auto-Scroll)
                            Expanded(
                              // UBAH DISINI: Panggil Class MonthFilterSelector
                              child: MonthFilterSelector(
                                provider: expenseProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. List Transaksi
                  _buildGroupedExpenseList(expenseProvider),

                  // Padding bawah untuk FAB
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // WIDGET: Kartu Utama (Gradient Blue)
  // WIDGET: Kartu Insight (Pengganti Total Biasa)
  Widget _buildHeroCard(ExpenseProvider provider) {
    // Hitung saldo, pemasukan, dan pengeluaran
    final balance = provider.balance;
    final totalIncome = provider.totalIncome;
    final totalExpense = provider.totalExpenses;

    // Hitung perbandingan bulan lalu (hanya berlaku jika filter di "Bulan Ini" atau "Semua" tapi defaultnya kita cek dari data asli)
    final now = DateTime.now();
    int prevMonth = now.month - 1;
    int prevYear = now.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }

    double prevMonthExpense = 0;
    for (var expense in provider.allExpenses) {
      if (expense.type == 'expense' && 
          expense.date.month == prevMonth && 
          expense.date.year == prevYear) {
        prevMonthExpense += expense.amount;
      }
    }

    double diffPercentage = 0;
    bool isHemat = true;
    if (prevMonthExpense > 0) {
      if (totalExpense <= prevMonthExpense) {
        isHemat = true;
        diffPercentage = ((prevMonthExpense - totalExpense) / prevMonthExpense) * 100;
      } else {
        isHemat = false;
        diffPercentage = ((totalExpense - prevMonthExpense) / prevMonthExpense) * 100;
      }
    }

    // Formatter
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final compactFormat = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String heroTitle;
    if (provider.selectedMonthFilter == MonthFilter.all) {
      heroTitle = "Saldo Saat Ini";
    } else {
      heroTitle = "Saldo Bulan Ini";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[900]!,
            Colors.indigo[600]!, // Ubah sedikit warnanya biar lebih fresh
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Judul & Rata-rata Harian
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heroTitle,
                    style: TextStyle(
                      color: Colors.blue[100],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Total Besar (Saldo)
                  Text(
                    currencyFormat.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (prevMonthExpense > 0 && provider.selectedMonthFilter != MonthFilter.all) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHemat ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isHemat ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHemat ? Icons.trending_down : Icons.trending_up,
                            color: isHemat ? Colors.greenAccent : Colors.redAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${diffPercentage.toStringAsFixed(1)}% ${isHemat ? 'Lebih Hemat' : 'Lebih Boros'}',
                            style: TextStyle(
                              color: isHemat ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              // Icon Dekorasi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          const SizedBox(height: 16),

          // Baris Bawah: INSIGHT (Pemasukan & Pengeluaran)
          Row(
            children: [
              // 1. Info Pemasukan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pemasukan",
                      style: TextStyle(color: Colors.blue[200], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compactFormat.format(totalIncome),
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Garis tengah kecil
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 16),

              // 2. Info Pengeluaran
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pengeluaran",
                      style: TextStyle(color: Colors.blue[200], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compactFormat.format(totalExpense),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // GANTI method _buildChartSection dengan ini:
  Widget _buildChartSection(
    ExpenseProvider provider,
    List<ChartData> chartData,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white, // Tetap Putih
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06), // Shadow sangat halus
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Analisis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Pengeluaran per Kategori",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Tombol Filter Bulan
              MonthPickerButton(
                selectedMonth: provider.selectedMonthFilter,
                onMonthChanged: (month) => provider.setMonthFilter(month),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // B. EXPENSE CHART
          SizedBox(
            height: 280,
            child: ExpenseChart(
              totalAmount: provider.totalExpenses,
              chartData: chartData,
              period: provider.getCurrentMonthYear(),
            ),
          ),

          const SizedBox(height: 32),

          // C. DIVIDER
          Divider(color: Colors.grey[100], thickness: 1.5),
          const SizedBox(height: 24),

          // D. LIST KATEGORI
          CategoryBreakdown(
            categoryTotals: provider.getCategoryTotals(),
            totalAmount: provider.totalExpenses,
          ),
        ],
      ),
    );
  }

  // WIDGET: List Transaksi Model Kartu Harian (REVAMP TOTAL)
  // WIDGET: List Transaksi dengan Gaya Kartu Terpisah (Monthly Report Style)
  Widget _buildGroupedExpenseList(ExpenseProvider provider) {
    if (provider.expenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: Colors.blue[300],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum ada transaksi',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1. Grouping Data
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in provider.expenses) {
      final dateKey =
          DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          ).toString();
      if (!groupedExpenses.containsKey(dateKey)) {
        groupedExpenses[dateKey] = [];
      }
      groupedExpenses[dateKey]!.add(expense);
    }

    final sortedKeys =
        groupedExpenses.keys.toList()
          ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    // 2. Build UI List
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final dateKey = sortedKeys[index];
          final expenses = groupedExpenses[dateKey]!;
          final date = DateTime.parse(dateKey);
          final dailyTotal = expenses.fold(
            0.0,
            (sum, item) => item.type == 'income' ? sum + item.amount : sum - item.amount,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. HEADER TANGGAL (Transparan & Minimalis)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tanggal
                    Row(
                      children: [
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE',
                                'id_ID',
                              ).format(date).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM yyyy', 'id_ID').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Total Harian
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        (dailyTotal >= 0 ? '+' : '-') + NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(dailyTotal.abs()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: dailyTotal >= 0 ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // B. LIST ITEM (Individual Cards)
              ...expenses.map((expense) {
                return _buildExpenseCard(context, expense, provider);
              }).toList(),
            ],
          );
        }, childCount: sortedKeys.length),
      ),
    );
  }

  Widget _buildMonthBadges(ExpenseProvider provider) {
    final List<MonthFilter> options = [
      MonthFilter.all,
      ...MonthFilter.values.where((m) => m != MonthFilter.all),
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      // HAPUS padding horizontal di sini agar scroll mentok ke tepi
      itemCount: options.length,
      itemBuilder: (context, index) {
        final month = options[index];
        final isSelected = provider.selectedMonthFilter == month;

        String label;
        if (month == MonthFilter.all) {
          label = "Semua";
        } else {
          label = Constants.months[month.index].substring(0, 3);
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => provider.setMonthFilter(month),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.blue[800]! : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center, // Pastikan teks di tengah
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // WIDGET ITEM: Gaya Kartu Terpisah (Monthly Report Style)
  Widget _buildExpenseCard(
    BuildContext context,
    Expense expense,
    ExpenseProvider provider,
  ) {
    final style = Constants.getCategoryStyle(expense.category);
    final color = style['color'] as Color;
    final icon = style['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Jarak antar kartu
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Radius membulat
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedTap(
          onTap: () => _showExpenseOptions(context, expense), // Buka menu opsi
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. Ikon Kategori (Kotak Rounded)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), // Warna pastel transparan
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),

                const SizedBox(width: 16),

                // 2. Info Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title.isNotEmpty
                            ? expense.title
                            : expense.category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Tampilkan Kategori jika ada judul, atau Jam jika tidak ada judul
                      Text(
                        expense.title.isNotEmpty
                            ? "${expense.category} • ${DateFormat('HH:mm').format(expense.date)}"
                            : DateFormat('HH:mm').format(expense.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Nominal
                Text(
                  (expense.type == 'income' ? '+ ' : '- ') + NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(expense.amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: expense.type == 'income' ? Colors.green[700] : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ChartData> _prepareChartData(ExpenseProvider provider) {
    final categoryData = provider.getCategoryDataForChart();
    final chartData = <ChartData>[];

    categoryData.forEach((category, amount) {
      if (amount > 0) {
        chartData.add(
          ChartData(category, amount, provider.getCategoryColor(category)),
        );
      }
    });

    if (chartData.isEmpty) {
      chartData.add(ChartData('Tidak ada data', 1.0, Colors.grey[300]!));
    }
    return chartData;
  }

  void _showEditExpense(BuildContext context, Expense expense) {
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditExpenseScreen(
              expense: expense,
              onSave:
                  (updatedExpense) =>
                      expenseProvider.editExpense(updatedExpense),
            ),
      ),
    );
  }

  void _showExpenseOptions(BuildContext context, Expense expense) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Formatter Tanggal Lengkap (Hari, Tgl Bulan Tahun • Jam)
    final dateString = DateFormat(
      'EEEE, d MMMM yyyy • HH:mm',
      'id_ID',
    ).format(expense.date);

    final style = Constants.getCategoryStyle(expense.category);
    final color = style['color'] as Color;
    final icon = style['icon'] as IconData;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // 2. Header: Detail Transaksi + Waktu
                Row(
                  children: [
                    // Ikon Kategori
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Info Teks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul / Kategori
                          Text(
                            expense.title.isNotEmpty
                                ? expense.title
                                : expense.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // INFO WAKTU (BARU)
                          Text(
                            dateString,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Nominal
                          Text(
                            currencyFormatter.format(expense.amount),
                            style: const TextStyle(
                              fontSize: 16, // Sedikit lebih besar biar jelas
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 3. Tombol Edit
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditExpense(context, expense);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: const Text("Edit Transaksi"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: Colors.black87,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Tombol Hapus
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, provider, expense.id);
                    },
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    label: Text(
                      "Hapus Transaksi",
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Helper untuk Konfirmasi Hapus (Dialog Terpisah)
  void _confirmDelete(
    BuildContext context,
    ExpenseProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Hapus Transaksi?"),
            content: const Text(
              "Data ini akan dihapus permanen dan tidak bisa dikembalikan.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  provider.deleteExpense(id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaksi berhasil dihapus")),
                  );
                },
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight; // Property baru
  final double maxHeight; // Property baru

  _StickyFilterDelegate({
    required this.child,
    this.minHeight = 70.0, // Default height jika tidak diisi
    this.maxHeight = 70.0, // Default height jika tidak diisi
  });

  @override
  double get minExtent => minHeight; // Gunakan variable

  @override
  double get maxExtent => maxHeight; // Gunakan variable

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyFilterDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}
