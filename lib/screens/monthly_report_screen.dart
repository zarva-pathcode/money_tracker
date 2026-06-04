import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/models/chart_data.dart';
import 'package:money_tracker/utils/constants.dart';
import 'package:money_tracker/widgets/category_breakdown.dart';
import 'package:money_tracker/widgets/expense_chart.dart';
import 'package:money_tracker/widgets/month_picker_button.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/analysis_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/plan_provider.dart';
import 'monthly_report_detail_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  bool _showIncome = false;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final analysisProvider =
        context.read<AnalysisProvider>();
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final planProvider = Provider.of<PlanProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                pinned: true,
                floating: true,
                automaticallyImplyLeading: false,
                title: const Text(
                  "Statistik",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                bottom: TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "Bulanan"),
                    Tab(text: "Tahunan"),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildMonthlyTab(context, expenseProvider, analysisProvider, budgetProvider),
              _buildYearlyTab(context, expenseProvider, analysisProvider, planProvider),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: BULANAN (Analisis Mendalam)
  // ==========================================
  Widget _buildMonthlyTab(
    BuildContext context,
    ExpenseProvider expenseProvider,
    AnalysisProvider analysisProvider,
    BudgetProvider budgetProvider,
  ) {
    final isIncome = _showIncome;
    final chartData = isIncome
        ? _prepareIncomeChartData(analysisProvider)
        : _prepareChartData(analysisProvider);
    final totalAmount =
        isIncome ? analysisProvider.filteredIncome : expenseProvider.totalExpenses;
    final subtitle = isIncome ? "Pemasukan per Kategori" : "Pengeluaran per Kategori";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Grafik Donut & Breakdown
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
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
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildTypeToggle(context),
                    const SizedBox(width: 8),
                    MonthPickerButton(
                      selectedMonth: expenseProvider.selectedMonthFilter,
                      onMonthChanged: (month) => expenseProvider.setMonthFilter(month),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 280,
                  child: ExpenseChart(
                    totalAmount: totalAmount,
                    chartData: chartData,
                    period: analysisProvider.currentMonthYear,
                  ),
                ),
                const SizedBox(height: 32),
                Divider(color: Colors.grey[100], thickness: 1.5),
                const SizedBox(height: 24),
                if (isIncome)
                  _buildIncomeCategoryBreakdown(context, expenseProvider)
                else
                  _buildUnifiedCategoryAnalysis(context, expenseProvider, budgetProvider),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    final isIncome = _showIncome;
    return GestureDetector(
      onTap: () => setState(() => _showIncome = !_showIncome),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isIncome ? Colors.green : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              isIncome ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isIncome ? 'In' : 'Out',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: TAHUNAN (Tren & Riwayat)
  // ==========================================
  Widget _buildYearlyTab(
    BuildContext context,
    ExpenseProvider expenseProvider,
    AnalysisProvider analysisProvider,
    PlanProvider planProvider,
  ) {
    final currentYear = DateTime.now().year;
    final monthlyExpenses = analysisProvider.getMonthlyExpenseTotals(currentYear);
    final monthlyIncomes = analysisProvider.getMonthlyIncomeTotals(currentYear);

    final chartData = monthlyExpenses.entries.map((e) {
      return _YearlyChartData(
        month: Constants.months[e.key - 1].substring(0, 3),
        expense: e.value,
        income: monthlyIncomes[e.key] ?? 0,
        monthIndex: e.key,
      );
    }).toList();

    final currentMonthIndex = DateTime.now().month;
    final totalExpenseYear = monthlyExpenses.values.fold(0.0, (sum, v) => sum + v);
    final totalIncomeYear = monthlyIncomes.values.fold(0.0, (sum, v) => sum + v);
    final averageMonthlyExpense =
        currentMonthIndex > 0 ? totalExpenseYear / currentMonthIndex : 0.0;
    final averageMonthlyIncome =
        currentMonthIndex > 0 ? totalIncomeYear / currentMonthIndex : 0.0;

    final activeExpenseMonths =
        monthlyExpenses.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final highestMonth =
        activeExpenseMonths.isNotEmpty ? activeExpenseMonths.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildYearlyChartSection(context, chartData),
          const SizedBox(height: 20),
          _buildStatsGrid(
            context,
            averageMonthlyExpense,
            averageMonthlyIncome,
            highestMonth,
          ),
          const SizedBox(height: 24),
          _buildWealthCard(context, expenseProvider, planProvider),
          const SizedBox(height: 24),
          _buildMonthlyList(
            context,
            monthlyExpenses,
            monthlyIncomes,
            expenseProvider,
          ),
          const SizedBox(height: 24),
          _buildGoalsSummary(context, planProvider, expenseProvider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper untuk data Donut Chart
  List<ChartData> _prepareChartData(AnalysisProvider provider) {
    final categoryData = provider.getCategoryDataForChart();
    final chartData = <ChartData>[];

    categoryData.forEach((category, amount) {
      if (amount > 0) {
        final color = Constants.getCategoryStyle(category)['color'] as Color;
        chartData.add(
          ChartData(category, amount, color),
        );
      }
    });

    if (chartData.isEmpty) {
      chartData.add(ChartData('Tidak ada data', 1.0, Colors.grey[300]!));
    }
    return chartData;
  }

  List<ChartData> _prepareIncomeChartData(AnalysisProvider provider) {
    final categoryData = provider.getIncomeCategoryDataForChart();
    final chartData = <ChartData>[];

    categoryData.forEach((category, amount) {
      if (amount > 0) {
        final color = Constants.getCategoryStyle(category)['color'] as Color;
        chartData.add(
          ChartData(category, amount, color),
        );
      }
    });

    if (chartData.isEmpty) {
      chartData.add(ChartData('Tidak ada data', 1.0, Colors.grey[300]!));
    }
    return chartData;
  }

  Widget _buildIncomeCategoryBreakdown(
    BuildContext context,
    ExpenseProvider expenseProvider,
  ) {
    final analysisProvider = context.read<AnalysisProvider>();
    final categoryTotals = analysisProvider.getIncomeCategoryTotals();
    final totalAmount = analysisProvider.filteredIncome;

    if (categoryTotals.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'Belum ada pemasukan bulan ini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ),
      );
    }

    final sortedEntries =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final currencyFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...sortedEntries.map((entry) {
          final categoryName = entry.key;
          final amount = entry.value;
          final percent = totalAmount > 0 ? amount / totalAmount : 0.0;

          final style = Constants.getCategoryStyle(categoryName);
          final color = style['color'] as Color;
          final icon = style['icon'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: FaIcon(icon, color: color, size: 16)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[100],
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildYearlyChartSection(BuildContext context, List<_YearlyChartData> data) {
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
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(Colors.green, 'Pemasukan'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 12),
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
                  xValueMapper: (_YearlyChartData d, _) => d.month,
                  yValueMapper: (_YearlyChartData d, _) => d.income,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: Colors.green[400],
                  spacing: 0.2,
                  width: 0.3,
                ),
                ColumnSeries<_YearlyChartData, String>(
                  dataSource: data,
                  xValueMapper: (_YearlyChartData d, _) => d.month,
                  yValueMapper: (_YearlyChartData d, _) => d.expense,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: Theme.of(context).primaryColor,
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

  Widget _buildStatsGrid(
    BuildContext context,
    double avgExpense,
    double avgIncome,
    MapEntry<int, double>? highest,
  ) {
    final surplus = avgIncome - avgExpense;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard("Rata-rata Pengeluaran", avgExpense, Icons.show_chart_rounded, Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard("Rata-rata Pemasukan", avgIncome, Icons.trending_up_rounded, Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Paling Boros",
                highest?.value ?? 0,
                Icons.warning_amber_rounded,
                Colors.red,
                subtitle: highest != null ? Constants.months[highest.key - 1] : "-",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Surplus Rata-rata",
                surplus > 0 ? surplus : 0,
                Icons.savings_rounded,
                surplus > 0 ? Colors.teal : Colors.grey,
                subtitle: surplus > 0 ? "Positif" : (surplus < 0 ? "Defisit" : "Imbang"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    dynamic icon,
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
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(value),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyList(
    BuildContext context,
    Map<int, double> monthlyExpenses,
    Map<int, double> monthlyIncomes,
    ExpenseProvider provider,
  ) {
    final currentMonth = DateTime.now().month;
    final activeMonths = monthlyExpenses.keys.where((m) => m <= currentMonth).toList();
    activeMonths.sort((a, b) => b.compareTo(a));

    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final compactFormat =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Riwayat Bulanan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeMonths.length,
          itemBuilder: (context, index) {
            final month = activeMonths[index];
            final expense = monthlyExpenses[month]!;
            final income = monthlyIncomes[month] ?? 0;
            final saving = income - expense;

            double? prevExpense;
            if (month > 1) prevExpense = monthlyExpenses[month - 1];

            bool isHigher = false;
            bool isSaving = false;
            if (prevExpense != null && prevExpense > 0) {
              isHigher = expense > prevExpense;
              isSaving = expense < prevExpense;
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
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final monthExpenses = provider.allExpenses
                      .where((e) =>
                          e.date.month == month && e.date.year == DateTime.now().year)
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MonthlyReportDetailScreen(month: month, expenses: monthExpenses),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          Constants.months[month - 1].substring(0, 3).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Out: ${compactFormat.format(expense)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'In: ${compactFormat.format(income)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  saving >= 0 ? Icons.savings_rounded : Icons.warning_rounded,
                                  size: 12,
                                  color: saving >= 0 ? Colors.teal : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  saving >= 0
                                      ? 'Surplus ${compactFormat.format(saving)}'
                                      : 'Defisit ${compactFormat.format(saving.abs())}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: saving >= 0 ? Colors.teal : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (month > 1) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    isHigher
                                        ? Icons.trending_up
                                        : (isSaving ? Icons.trending_down : Icons.remove),
                                    size: 12,
                                    color: isHigher
                                        ? Colors.red
                                        : (isSaving ? Colors.green : Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnifiedCategoryAnalysis(
    BuildContext context,
    ExpenseProvider expenseProvider,
    BudgetProvider budgetProvider,
  ) {
    final analysisProvider = context.read<AnalysisProvider>();
    final categoryTotals = analysisProvider.getCategoryTotals();
    final budgets = budgetProvider.budgets;
    final totalAmount = expenseProvider.totalExpenses;

    if (categoryTotals.isEmpty) return const SizedBox();

    final sortedEntries =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final currencyFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...sortedEntries.map((entry) {
          final categoryName = entry.key;
          final spentAmount = entry.value;

          // Cari apakah ada budget untuk kategori ini
          final budget = budgets.cast<dynamic>().firstWhere(
            (b) => b.category == categoryName,
            orElse: () => null,
          );

          double progress;
          String label;
          Color progressColor;

          if (budget != null) {
            progress = spentAmount / budget.limitAmount;
            label =
                "${currencyFormatter.format(spentAmount)} / ${currencyFormatter.format(budget.limitAmount)}";

            if (progress >= 1.0) {
              progress = 1.0;
              progressColor = Colors.red;
            } else if (progress >= 0.8) {
              progressColor = Colors.orange;
            } else {
              progressColor = Colors.green;
            }
          } else {
            progress = totalAmount == 0 ? 0 : spentAmount / totalAmount;
            label = currencyFormatter.format(spentAmount);
            progressColor = Theme.of(context).primaryColor;
          }

          final style = Constants.getCategoryStyle(categoryName);
          final color = style['color'] as Color;
          final icon = style['icon'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: FaIcon(icon, color: color, size: 16)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[100],
                          color: budget != null ? progressColor : color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWealthCard(
    BuildContext context,
    ExpenseProvider expenseProvider,
    PlanProvider planProvider,
  ) {
    final analysisProvider = context.read<AnalysisProvider>();
    final allTimeBal = analysisProvider.allTimeBalance;
    final totalGoals =
        planProvider.plans.fold<double>(0, (sum, p) => sum + p.currentAmount);
    final totalWealth = allTimeBal + totalGoals;

    final compactFormat =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.chartLine, color: Colors.white.withOpacity(0.8), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Total Kekayaan',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalWealth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tersedia', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      compactFormat.format(allTimeBal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ditabung', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      compactFormat.format(totalGoals),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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

  Widget _buildGoalsSummary(BuildContext context, PlanProvider planProvider,
      ExpenseProvider expenseProvider) {
    final analysisProvider = context.read<AnalysisProvider>();
    final plans = planProvider.plans;
    if (plans.isEmpty) return const SizedBox();

    final now = DateTime.now();
    final savedThisMonth = analysisProvider.totalSavingsAllTime;
    // Calculate this month's savings (Tabungan expenses) and withdrawals (Tabungan income)
    final thisMonthSavings = expenseProvider.allExpenses
        .where((e) =>
            e.type == 'expense' &&
            e.category == 'Tabungan' &&
            e.date.month == now.month &&
            e.date.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final thisMonthWithdrawals = expenseProvider.allExpenses
        .where((e) =>
            e.type == 'income' &&
            e.category == 'Tabungan' &&
            e.date.month == now.month &&
            e.date.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final netSaving = thisMonthSavings - thisMonthWithdrawals;

    final compactFormat =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progres Tabungan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        // Net saving card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: netSaving >= 0 ? Colors.teal[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: netSaving >= 0 ? Colors.teal[200]! : Colors.orange[200]!,
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                netSaving >= 0 ? FontAwesomeIcons.piggyBank : FontAwesomeIcons.arrowRight,
                color: netSaving >= 0 ? Colors.teal : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      netSaving >= 0 ? 'Bulan ini menabung' : 'Bulan ini menarik tabungan',
                      style: TextStyle(
                        fontSize: 12,
                        color: netSaving >= 0 ? Colors.teal[700] : Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Net: ${compactFormat.format(netSaving.abs())}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: netSaving >= 0 ? Colors.teal[800] : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: netSaving >= 0 ? Colors.teal : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${netSaving >= 0 ? '+' : ''}${compactFormat.format(netSaving)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                        FaIcon(plan.icon, color: plan.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${(plan.progressPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: plan.color, fontSize: 16),
                    ),
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
  final double expense;
  final double income;
  final int monthIndex;

  _YearlyChartData({
    required this.month,
    required this.expense,
    required this.income,
    required this.monthIndex,
  });
}
