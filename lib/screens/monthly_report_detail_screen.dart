import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

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
      return _DetailChartData(entry.key, entry.value, style['color']);
    }).toList();

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
          "Laporan ${Constants.months[widget.month - 1]}",
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

            // B. WEEKLY CHART (dual)
            const Text("Tren Mingguan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDualWeeklyChart(context, weeklyChartData),
            const SizedBox(height: 24),

            // C. TOP TRANSACTIONS
            if (topExpenses.isNotEmpty) ...[
              const Text("Pengeluaran Terbesar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTopList(topExpenses.take(3).toList(), currencyFormat, Colors.red),
              const SizedBox(height: 20),
            ],
            if (topIncomes.isNotEmpty) ...[
              const Text("Pemasukan Terbesar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTopList(topIncomes.take(3).toList(), currencyFormat, Colors.green),
              const SizedBox(height: 24),
            ],

            // D. DISTRIBUSI KATEGORI with toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Distribusi Kategori",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                _buildCategoryToggle(context),
              ],
            ),
            const SizedBox(height: 12),
            if (categoryChartData.isNotEmpty) ...[
              _buildCategoryDonut(categoryChartData, totalActive),
              const SizedBox(height: 16),
              _buildCategoryList(categoryTotals, totalActive, currencyFormat),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryToggle(BuildContext context) {
    final isIncome = _showIncome;
    return GestureDetector(
      onTap: () => setState(() => _showIncome = !_showIncome),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isIncome ? Colors.green : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              isIncome ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
              color: Colors.white,
              size: 11,
            ),
            const SizedBox(width: 4),
            Text(
              isIncome ? 'In' : 'Out',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Ringkasan Bulan Ini",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.arrowUp, color: Colors.redAccent, size: 16),
                    const SizedBox(height: 4),
                    Text('Pengeluaran', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      compactFmt.format(totalExpense),
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.arrowDown, color: Colors.greenAccent, size: 16),
                    const SizedBox(height: 4),
                    Text('Pemasukan', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      compactFmt.format(totalIncome),
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: Column(
                  children: [
                    Icon(saving >= 0 ? Icons.savings_rounded : Icons.warning_rounded,
                        color: saving >= 0 ? Colors.tealAccent : Colors.orangeAccent, size: 16),
                    const SizedBox(height: 4),
                    Text('Sisa', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      compactFmt.format(saving.abs()),
                      style: TextStyle(
                        color: saving >= 0 ? Colors.tealAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: saving >= 0 ? Colors.teal.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              saving >= 0 ? 'Surplus ${fmt.format(saving)}' : 'Defisit ${fmt.format(saving.abs())}',
              style: TextStyle(
                color: saving >= 0 ? Colors.tealAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualWeeklyChart(BuildContext context, List<_WeeklyDualData> data) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, 'Income'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Expense'),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: Colors.green[400],
                  spacing: 0.2,
                  width: 0.3,
                ),
                ColumnSeries<_WeeklyDualData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.week,
                  yValueMapper: (d, _) => d.expense,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: Colors.red[400],
                  spacing: 0.2,
                  width: 0.3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTopList(List<Expense> list, NumberFormat fmt, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: list.map((e) {
          final style = Constants.getCategoryStyle(e.category);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (style['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(style['icon'], color: style['color'], size: 16),
            ),
            title: Text(
              e.title.isNotEmpty ? e.title : e.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(DateFormat('dd MMM').format(e.date), style: const TextStyle(fontSize: 12)),
            trailing: Text(fmt.format(e.amount), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: accentColor)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryDonut(List<_DetailChartData> data, double total) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        series: <CircularSeries>[
          DoughnutSeries<_DetailChartData, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.category,
            yValueMapper: (d, _) => d.amount,
            pointColorMapper: (d, _) => d.color,
            radius: '85%',
            innerRadius: '70%',
            strokeColor: Colors.white,
            strokeWidth: 2,
            cornerStyle: CornerStyle.bothCurve,
            dataLabelMapper: (d, _) => (d.amount / total * 100) > 5
                ? "${(d.amount / total * 100).toStringAsFixed(0)}%"
                : null,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              connectorLineSettings: ConnectorLineSettings(type: ConnectorType.curve, length: '10%'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> totals, double total, NumberFormat fmt) {
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((e) {
        final style = Constants.getCategoryStyle(e.key);
        final percent = total > 0 ? e.value / total : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  FaIcon(style['icon'], color: style['color'], size: 16),
                  const SizedBox(width: 12),
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(fmt.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.grey[100],
                  color: style['color'],
                  minHeight: 6,
                ),
              ),
            ],
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

class _DetailChartData {
  final String category;
  final double amount;
  final Color color;
  _DetailChartData(this.category, this.amount, this.color);
}
