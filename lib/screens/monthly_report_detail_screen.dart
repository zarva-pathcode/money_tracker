import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class MonthlyReportDetailScreen extends StatelessWidget {
  final int month;
  final List<Expense> expenses;

  const MonthlyReportDetailScreen({
    super.key,
    required this.month,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // 1. DATA PROCESSING
    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    // Group by Category
    final Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    // Group by Week (Minggu 1-5)
    final Map<String, double> weeklyTotals = {};
    for (var e in expenses) {
      // Hitung minggu ke berapa (1-5)
      final week = ((e.date.day - 1) / 7).floor() + 1;
      final key = "Minggu $week";
      weeklyTotals[key] = (weeklyTotals[key] ?? 0) + e.amount;
    }

    // Top 3 Transactions
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topTransactions = sortedExpenses.take(3).toList();

    // Prepare Chart Data
    final categoryChartData =
        categoryTotals.entries.map((entry) {
          final style = Constants.getCategoryStyle(entry.key);
          return _DetailChartData(entry.key, entry.value, style['color']);
        }).toList();

    final weeklyChartData =
        weeklyTotals.entries.map((e) => _WeeklyData(e.key, e.value)).toList()
          ..sort((a, b) => a.week.compareTo(b.week));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Laporan ${Constants.months[month - 1]}",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. HERO TOTAL
            _buildTotalCard(totalAmount),
            const SizedBox(height: 24),

            // B. ANALISIS MINGGUAN (FITUR BARU!)
            const Text(
              "Tren Mingguan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWeeklyChart(weeklyChartData),

            const SizedBox(height: 24),

            // C. TOP TRANSAKSI (FITUR BARU!)
            if (topTransactions.isNotEmpty) ...[
              const Text(
                "Pengeluaran Terbesar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTopTransactions(topTransactions, currencyFormat),
              const SizedBox(height: 24),
            ],

            // D. DISTRIBUSI KATEGORI
            const Text(
              "Distribusi Kategori",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCategoryDonut(categoryChartData, totalAmount),
            const SizedBox(height: 16),
            _buildCategoryList(categoryTotals, totalAmount, currencyFormat),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.indigo[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Bulan Ini",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BARU: Bar Chart Mingguan
  Widget _buildWeeklyChart(List<_WeeklyData> data) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        primaryYAxis: NumericAxis(isVisible: false, minimum: 0),
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: '',
          format: 'point.y',
        ),
        series: <CartesianSeries<_WeeklyData, String>>[
          ColumnSeries<_WeeklyData, String>(
            dataSource: data,
            xValueMapper: (_WeeklyData data, _) => data.week,
            yValueMapper: (_WeeklyData data, _) => data.amount,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            color: Colors.indigo[400],
            isTrackVisible: true, // Track background abu-abu
            trackColor: Colors.grey[100]!,
          ),
        ],
      ),
    );
  }

  // WIDGET BARU: Top 3 List
  Widget _buildTopTransactions(List<Expense> topList, NumberFormat fmt) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            topList.map((e) {
              final style = Constants.getCategoryStyle(e.category);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (style['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style['icon'], color: style['color'], size: 20),
                ),
                title: Text(
                  e.title.isNotEmpty ? e.title : e.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMM').format(e.date),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  fmt.format(e.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        series: <CircularSeries>[
          DoughnutSeries<_DetailChartData, String>(
            dataSource: data,
            xValueMapper: (data, _) => data.category,
            yValueMapper: (data, _) => data.amount,
            pointColorMapper: (data, _) => data.color,
            radius: '85%',
            innerRadius: '70%',
            strokeColor: Colors.white,
            strokeWidth: 2,
            cornerStyle: CornerStyle.bothCurve,
            dataLabelMapper:
                (data, _) =>
                    (data.amount / total * 100) > 5
                        ? "${(data.amount / total * 100).toStringAsFixed(0)}%"
                        : null,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              connectorLineSettings: ConnectorLineSettings(
                type: ConnectorType.curve,
                length: '10%',
              ),
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
  ) {
    final sorted =
        totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children:
          sorted.map((e) {
            final style = Constants.getCategoryStyle(e.key);
            final percent = total > 0 ? e.value / total : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(style['icon'], color: style['color'], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        e.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        fmt.format(e.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

class _WeeklyData {
  final String week;
  final double amount;
  _WeeklyData(this.week, this.amount);
}

class _DetailChartData {
  final String category;
  final double amount;
  final Color color;
  _DetailChartData(this.category, this.amount, this.color);
}
