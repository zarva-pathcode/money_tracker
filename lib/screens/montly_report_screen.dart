import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/plan_provider.dart';
import 'monthly_report_detail_screen.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final planProvider = Provider.of<PlanProvider>(context);

    // 1. OLAHKAN DATA (Group by Month 1-12)
    final expenses = expenseProvider.allExpenses;
    final currentYear = DateTime.now().year;

    // Map<Bulan(int), Total(double)>
    final Map<int, double> monthlyTotals = {};

    // Isi default 0 untuk bulan 1-12
    for (int i = 1; i <= 12; i++) {
      monthlyTotals[i] = 0.0;
    }

    // Isi data sebenarnya (Hanya tahun ini)
    for (var e in expenses) {
      if (e.date.year == currentYear) {
        monthlyTotals[e.date.month] =
            (monthlyTotals[e.date.month] ?? 0) + e.amount;
      }
    }

    // Siapkan Data Chart
    final chartData =
        monthlyTotals.entries.map((e) {
          return _YearlyChartData(
            month: Constants.months[e.key - 1].substring(0, 3), // Jan, Feb
            amount: e.value,
            monthIndex: e.key,
          );
        }).toList();

    // Hitung Statistik
    final totalYear = monthlyTotals.values.fold(0.0, (sum, val) => sum + val);
    final currentMonthIndex = DateTime.now().month;
    // Rata-rata dibagi bulan yang sudah berjalan saja (biar akurat)
    final averageMonthly =
        currentMonthIndex > 0 ? totalYear / currentMonthIndex : 0.0;

    // Cari Bulan Terboros & Terhemat (yang > 0)
    final activeMonths =
        monthlyTotals.entries.where((e) => e.value > 0).toList();
    activeMonths.sort((a, b) => b.value.compareTo(a.value)); // Sort Descending

    final highestMonth = activeMonths.isNotEmpty ? activeMonths.first : null;
    final lowestMonth = activeMonths.isNotEmpty ? activeMonths.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back arrow
        title: Text(
          "Statistik $currentYear",
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
            // 1. GRAFIK TREN TAHUNAN (Bar Chart)
            _buildYearlyChartSection(chartData),

            const SizedBox(height: 20),

            // 2. GRID STATISTIK (Avg, Highest, Lowest)
            _buildStatsGrid(averageMonthly, highestMonth, lowestMonth),

            const SizedBox(height: 24),

            // 3. STATUS ANGGARAN BULAN INI
            _buildBudgetsSummary(context, budgetProvider, expenseProvider),

            const SizedBox(height: 24),

            // 4. PROGRES TABUNGAN
            _buildGoalsSummary(context, planProvider),

            const SizedBox(height: 24),

            // 5. LIST BULANAN (Trend List)
            const Text(
              "Riwayat Bulanan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildMonthlyList(context, monthlyTotals, expenseProvider),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // SECTION 1: CHART TAHUNAN
  Widget _buildYearlyChartSection(List<_YearlyChartData> data) {
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grafik Tahunan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              primaryYAxis: NumericAxis(isVisible: false, minimum: 0),
              plotAreaBorderWidth: 0,
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                format: 'point.y',
              ),
              series: <CartesianSeries<_YearlyChartData, String>>[
                ColumnSeries<_YearlyChartData, String>(
                  dataSource: data,
                  xValueMapper: (_YearlyChartData data, _) => data.month,
                  yValueMapper: (_YearlyChartData data, _) => data.amount,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  color: Colors.blue[700],
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[300]!],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 2: STATISTIK GRID (Kartu Kecil)
  Widget _buildStatsGrid(
    double avg,
    MapEntry<int, double>? highest,
    MapEntry<int, double>? lowest,
  ) {
    return Row(
      children: [
        // Kartu Rata-rata
        Expanded(
          child: _buildStatCard(
            "Rata-rata",
            avg,
            Icons.show_chart_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        // Kartu Terboros
        Expanded(
          child: _buildStatCard(
            "Paling Boros",
            highest?.value ?? 0,
            Icons.warning_amber_rounded,
            Colors.red,
            subtitle: highest != null ? Constants.months[highest.key - 1] : "-",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 1,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(value),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // SECTION 3: LIST BULANAN DENGAN TREND
  Widget _buildMonthlyList(
    BuildContext context,
    Map<int, double> monthlyTotals,
    ExpenseProvider provider,
  ) {
    // Filter hanya bulan yang sudah lewat/sekarang (biar gak kosong banyak ke bawah)
    final currentMonth = DateTime.now().month;
    final activeMonths =
        monthlyTotals.keys.where((m) => m <= currentMonth).toList();
    // Urutkan dari bulan terbaru (Des -> Jan)
    activeMonths.sort((a, b) => b.compareTo(a));

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeMonths.length,
      itemBuilder: (context, index) {
        final month = activeMonths[index];
        final total = monthlyTotals[month]!;

        // Hitung Trend (Bandingkan dengan bulan sebelumnya)
        double? prevTotal;
        if (month > 1) prevTotal = monthlyTotals[month - 1];

        bool isSaving = false;
        bool isHigher = false;

        if (prevTotal != null && prevTotal > 0) {
          isHigher = total > prevTotal;
          isSaving = total < prevTotal;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () {
              // Navigasi ke Detail (Filter data dulu)
              final monthExpenses =
                  provider.allExpenses
                      .where(
                        (e) =>
                            e.date.month == month &&
                            e.date.year == DateTime.now().year,
                      )
                      .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MonthlyReportDetailScreen(
                        month: month,
                        expenses: monthExpenses,
                      ),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                Constants.months[month - 1].substring(0, 3).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 13,
                ),
              ),
            ),
            title: Text(
              currencyFormat.format(total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            // Indikator Trend (Naik/Turun)
            subtitle:
                (month == 1)
                    ? const Text(
                      "Awal Tahun",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                    : Row(
                      children: [
                        Icon(
                          isHigher
                              ? Icons.trending_up
                              : (isSaving ? Icons.trending_down : Icons.remove),
                          size: 14,
                          color:
                              isHigher
                                  ? Colors.red
                                  : (isSaving ? Colors.green : Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isHigher
                              ? "Naik dari bulan lalu"
                              : (isSaving ? "Lebih hemat" : "Stabil"),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isHigher
                                    ? Colors.red
                                    : (isSaving ? Colors.green : Colors.grey),
                          ),
                        ),
                      ],
                    ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetsSummary(BuildContext context, BudgetProvider budgetProvider, ExpenseProvider expenseProvider) {
    final budgets = budgetProvider.budgets;
    if (budgets.isEmpty) return const SizedBox();

    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Status Anggaran Bulan Ini",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        ...budgets.map((budget) {
          double spentAmount = 0;
          for (var expense in expenseProvider.allExpenses) {
            if (expense.category == budget.category && 
                expense.date.month == currentMonth && 
                expense.date.year == currentYear &&
                expense.type == 'expense') { 
              spentAmount += expense.amount;
            }
          }

          double progress = spentAmount / budget.limitAmount;
          if (progress > 1.0) progress = 1.0;

          Color progressColor = Colors.green;
          if (progress >= 0.85) progressColor = Colors.red;
          else if (progress >= 0.5) progressColor = Colors.orange;

          final categoryName = Constants.expenseCategories.firstWhere(
            (c) => c == budget.category,
            orElse: () => budget.category,
          );
          final categoryData = Constants.getCategoryStyle(categoryName);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(categoryData['icon'] as IconData, color: categoryData['color'] as Color, size: 20),
                        const SizedBox(width: 8),
                         Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: progressColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: progressColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGoalsSummary(BuildContext context, PlanProvider planProvider) {
    final plans = planProvider.plans;
    if (plans.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progres Tabungan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(plan.icon, color: plan.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Spacer(),
                    Text('${(plan.progressPercentage * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: plan.color, fontSize: 16)),
                    const SizedBox(height: 8),
                     ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: plan.progressPercentage,
                          backgroundColor: Colors.grey[200],
                          color: plan.color,
                          minHeight: 6,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YearlyChartData {
  final String month;
  final double amount;
  final int monthIndex;

  _YearlyChartData({
    required this.month,
    required this.amount,
    required this.monthIndex,
  });
}
