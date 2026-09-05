import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/chart_data.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../widgets/category_detail_bottom_sheet.dart';
import '../widgets/expense_chart.dart';

class MonthlyReportDetailScreen extends StatefulWidget {
  final int month;
  final List<Expense> expenses;

  const MonthlyReportDetailScreen({
    super.key,
    required this.month,
    required this.expenses,
  });

  @override
  State<MonthlyReportDetailScreen> createState() => _MonthlyReportDetailScreenState();
}

class _MonthlyReportDetailScreenState extends State<MonthlyReportDetailScreen> {
  bool _showIncome = false;

  @override
  Widget build(BuildContext context) {
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

    // Separate income and expense
    final expenses = widget.expenses.where((e) => e.type == 'expense').toList();
    final incomes = widget.expenses.where((e) => e.type == 'income').toList();

    final totalExpense = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold<double>(0, (sum, e) => sum + e.amount);
    final saving = totalIncome - totalExpense;

    // Weekly data (dual)
    final Map<int, double> weeklyExpenses = {};
    final Map<int, double> weeklyIncomes = {};
    for (var e in expenses) {
      final week = ((e.date.day - 1) / 7).floor() + 1;
      weeklyExpenses[week] = (weeklyExpenses[week] ?? 0) + e.amount;
    }
    for (var e in incomes) {
      final week = ((e.date.day - 1) / 7).floor() + 1;
      weeklyIncomes[week] = (weeklyIncomes[week] ?? 0) + e.amount;
    }
    final allWeeks = <int>{...weeklyExpenses.keys, ...weeklyIncomes.keys}.toList()..sort();
    final weeklyChartData = allWeeks.map((w) => _WeeklyDualData(
      week: 'Minggu $w',
      expense: weeklyExpenses[w] ?? 0,
      income: weeklyIncomes[w] ?? 0,
    )).toList();

    // Top transactions
    final topExpenses = List<Expense>.from(expenses)..sort((a, b) => b.amount.compareTo(a.amount));
    final topIncomes = List<Expense>.from(incomes)..sort((a, b) => b.amount.compareTo(a.amount));

    // Category data (filtered by _showIncome)
    final activeTransactions = _showIncome ? incomes : expenses;
    final totalActive = _showIncome ? totalIncome : totalExpense;
    final Map<String, double> categoryTotals = {};
    for (var e in activeTransactions) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final categoryChartData = categoryTotals.entries.map((entry) {
      final style = Constants.getCategoryStyle(entry.key);
      return ChartData(entry.key, entry.value, style.color);
    }).toList();
    // Kategori terbesar untuk pill highlight di bawah chart.
    String? topCategory;
    double topCategoryAmount = 0;
    categoryTotals.forEach((name, amount) {
      if (amount > topCategoryAmount) {
        topCategoryAmount = amount;
        topCategory = name;
      }
    });
    final topPercent =
        totalActive > 0 ? topCategoryAmount / totalActive : 0.0;

    // Label periode "April 2026" dari data transaksi (fallback tahun kini).
    final detailYear = widget.expenses.isNotEmpty
        ? widget.expenses.first.date.year
        : DateTime.now().year;
    final periodLabel = '${Constants.months[widget.month - 1]} $detailYear';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Laporan $periodLabel",
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. DUAL HERO
            _buildDualHeroCard(context, totalExpense, totalIncome, saving, currencyFormat, compactFormat),
            const SizedBox(height: 24),

            // B. WEEKLY CHART (dual, judul ada di dalam kartu)
            _buildDualWeeklyChart(context, weeklyChartData),
            const SizedBox(height: 24),

            // C. TOP TRANSACTIONS
            if (topExpenses.isNotEmpty) ...[
              const Text(
                "Pengeluaran Terbesar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildTopList(topExpenses.take(3).toList(), currencyFormat, Colors.red),
              const SizedBox(height: 20),
            ],
            if (topIncomes.isNotEmpty) ...[
              const Text(
                "Pemasukan Terbesar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildTopList(topIncomes.take(3).toList(), currencyFormat, Colors.green),
              const SizedBox(height: 24),
            ],

            // D. DISTRIBUSI KATEGORI: judul + toggle full-width di bawahnya
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Distribusi Kategori",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${categoryTotals.length} kategori",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCategoryToggle(context),
            const SizedBox(height: 12),
            if (categoryChartData.isNotEmpty) ...[
              _buildDistributionCard(
                totalActive: totalActive,
                chartData: categoryChartData,
                periodLabel: periodLabel,
                topCategory: topCategory,
                topAmount: topCategoryAmount,
                topPercent: topPercent,
                currencyFormat: currencyFormat,
              ),
              const SizedBox(height: 16),
              _buildCategoryList(
                categoryTotals,
                totalActive,
                currencyFormat,
                activeTransactions,
                periodLabel,
              ),
            ] else
              SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    _showIncome ? 'Belum ada pemasukan bulan ini' : 'Belum ada pengeluaran bulan ini',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ].animate(interval: 60.ms).fadeIn(duration: 350.ms, curve: Curves.easeOut).slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }

  Widget _buildCategoryToggle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            selected: !_showIncome,
            icon: FontAwesomeIcons.arrowUp,
            label: 'Pengeluaran',
            activeColor: Colors.red[700]!,
            onTap: () => setState(() => _showIncome = false),
          ),
          _buildToggleItem(
            selected: _showIncome,
            icon: FontAwesomeIcons.arrowDown,
            label: 'Pemasukan',
            activeColor: Colors.green[700]!,
            onTap: () => setState(() => _showIncome = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required bool selected,
    required FaIconData icon,
    required String label,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 12,
                color: selected ? activeColor : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.black87 : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDualHeroCard(
    BuildContext context,
    double totalExpense,
    double totalIncome,
    double saving,
    NumberFormat fmt,
    NumberFormat compactFmt,
  ) {
    final isSurplus = saving >= 0;
    final badgeColor = isSurplus ? Colors.green[700]! : Colors.red[700]!;
    final badgeBg = isSurplus ? Colors.green[50]! : Colors.red[50]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildHeroFlowItem(
                  icon: FontAwesomeIcons.arrowDown,
                  label: 'Pemasukan',
                  value: '+ ${compactFmt.format(totalIncome)}',
                  color: Colors.green[700]!,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.grey[200]),
              Expanded(
                child: _buildHeroFlowItem(
                  icon: FontAwesomeIcons.arrowUp,
                  label: 'Pengeluaran',
                  value: '− ${compactFmt.format(totalExpense)}',
                  color: Colors.red[700]!,
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey[100], thickness: 1.5, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arus Kas Bersih',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSurplus ? 'Surplus' : 'Defisit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              fmt.format(saving),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isSurplus ? Colors.black87 : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFlowItem({
    required FaIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDualWeeklyChart(BuildContext context, List<_WeeklyDualData> data) {
    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Mingguan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _legendPill(Colors.green[600]!, 'Pemasukan'),
              _legendPill(Colors.red[500]!, 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              primaryYAxis: NumericAxis(isVisible: false, minimum: 0),
              plotAreaBorderWidth: 0,
              tooltipBehavior: TooltipBehavior(enable: true, header: '', format: 'point.y'),
              series: <CartesianSeries<_WeeklyDualData, String>>[
                ColumnSeries<_WeeklyDualData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.week,
                  yValueMapper: (d, _) => d.income,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.green[500],
                  spacing: 0.25,
                  width: 0.35,
                ),
                ColumnSeries<_WeeklyDualData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.week,
                  yValueMapper: (d, _) => d.expense,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.red[400],
                  spacing: 0.25,
                  width: 0.35,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Legenda berbentuk pill untuk kartu grafik (anti-overflow via Wrap).
  Widget _legendPill(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopList(List<Expense> list, NumberFormat fmt, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: list.asMap().entries.map((entry) {
          final e = entry.value;
          final isLast = entry.key == list.length - 1;
          final style = Constants.getCategoryStyle(e.category);
          final catColor = style.color;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: FaIcon(style.icon, color: catColor, size: 17),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title.isNotEmpty ? e.title : e.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${DateFormat('dd MMM yyyy', 'id_ID').format(e.date)} • ${e.category}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmt.format(e.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, indent: 72, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Kartu distribusi kategori: ExpenseChart (teks tengah terintegrasi)
  /// + pill highlight kategori terbesar — identik dengan Tab Bulanan.
  Widget _buildDistributionCard({
    required double totalActive,
    required List<ChartData> chartData,
    required String periodLabel,
    required String? topCategory,
    required double topAmount,
    required double topPercent,
    required NumberFormat currencyFormat,
  }) {
    final title = _showIncome ? 'Distribusi Pemasukan' : 'Distribusi Pengeluaran';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ExpenseChart(
              totalAmount: totalActive,
              chartData: chartData,
              period: periodLabel,
            ),
          ),
          if (topCategory != null) ...[
            const SizedBox(height: 16),
            _buildTopCategoryPill(
              categoryName: topCategory,
              amount: topAmount,
              percent: topPercent,
              currency: currencyFormat,
            ),
          ],
        ],
      ),
    );
  }

  /// Pill highlight kategori terbesar bulan ini.
  Widget _buildTopCategoryPill({
    required String categoryName,
    required double amount,
    required double percent,
    required NumberFormat currency,
  }) {
    final style = Constants.getCategoryStyle(categoryName);
    final color = style.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.trophy, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terbesar bulan ini',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  '$categoryName • ${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currency.format(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    Map<String, double> totals,
    double total,
    NumberFormat fmt,
    List<Expense> activeTransactions,
    String periodLabel,
  ) {
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final type = _showIncome ? 'income' : 'expense';
    return Column(
      children: sorted.map((e) {
        final style = Constants.getCategoryStyle(e.key);
        final catColor = style.color;
        final percent = total > 0 ? e.value / total : 0.0;
        final catTransactions = activeTransactions
            .where((tx) => tx.category == e.key)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return GestureDetector(
          onTap: () {
            // Drill-down: seluruh transaksi kategori ini dalam sheet.
            CategoryDetailBottomSheet.show(
              context,
              categoryName: e.key,
              transactions: catTransactions,
              type: type,
              periodLabel: periodLabel,
              categoryTotal: e.value,
              grandTotal: total,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: FaIcon(style.icon, color: catColor, size: 19),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fmt.format(e.value),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[100],
                    color: catColor,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${(percent * 100).toStringAsFixed(1)}% dari total',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeeklyDualData {
  final String week;
  final double expense;
  final double income;
  _WeeklyDualData({required this.week, required this.expense, required this.income});
}
