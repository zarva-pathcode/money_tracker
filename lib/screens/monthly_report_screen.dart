import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/models/chart_data.dart';
import 'package:money_tracker/utils/constants.dart';

import 'package:money_tracker/widgets/category_detail_bottom_sheet.dart';
import 'package:money_tracker/widgets/expense_chart.dart';
import 'package:money_tracker/widgets/month_picker_button.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/analysis_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_export_service.dart';
import '../utils/linear_regression.dart';
import 'monthly_report_detail_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  bool _showIncome = false;
  int _selectedYear = DateTime.now().year;

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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.black87),
                    tooltip: 'Export PDF',
                    onPressed: () => _exportPdf(context),
                  ),
                ],
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

    final incomeTotal = analysisProvider.filteredIncome;
    final expenseTotal = expenseProvider.totalExpenses;
    final netFlow = incomeTotal - expenseTotal;
    final periodLabel = analysisProvider.currentMonthYear;

    // Kategori terbesar untuk highlight di bawah chart.
    final highlightTotals = isIncome
        ? analysisProvider.getIncomeCategoryTotals()
        : analysisProvider.getCategoryTotals();
    String? topCategory;
    double topCategoryAmount = 0;
    highlightTotals.forEach((name, amount) {
      if (amount > topCategoryAmount) {
        topCategoryAmount = amount;
        topCategory = name;
      }
    });
    final topPercent =
        totalAmount > 0 ? topCategoryAmount / totalAmount : 0.0;

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header + pemilih bulan
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Analisis Bulanan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      periodLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              MonthPickerButton(
                selectedMonth: expenseProvider.selectedMonthFilter,
                onMonthChanged: (month) => expenseProvider.setMonthFilter(month),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 2. Segmented switcher Pengeluaran / Pemasukan
          _buildModeSegment(context),
          const SizedBox(height: 16),
          // 3. Kartu hero arus kas bulanan
          _buildCashFlowHero(
            incomeTotal: incomeTotal,
            expenseTotal: expenseTotal,
            netFlow: netFlow,
            currency: currency,
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.1,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutQuad,
              ),
          const SizedBox(height: 16),
          // 4. Kartu donut + highlight kategori terbesar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                Text(
                  isIncome ? "Distribusi Pemasukan" : "Distribusi Pengeluaran",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: ExpenseChart(
                    totalAmount: totalAmount,
                    chartData: chartData,
                    period: periodLabel,
                  ),
                ),
                if (topCategory != null) ...[
                  const SizedBox(height: 16),
                  _buildTopCategoryPill(
                    categoryName: topCategory!,
                    amount: topCategoryAmount,
                    percent: topPercent,
                    currency: currency,
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(
                delay: 100.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .slideY(
                begin: 0.1,
                end: 0,
                delay: 100.ms,
                duration: 400.ms,
                curve: Curves.easeOutQuad,
              ),
          const SizedBox(height: 20),
          // 5. Judul rincian kategori
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rincian Kategori",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${highlightTotals.length} kategori",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isIncome
              ? _buildIncomeCategoryBreakdown(context, expenseProvider)
              : _buildUnifiedCategoryAnalysis(context, expenseProvider, budgetProvider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Segmented pill switcher Pengeluaran / Pemasukan.
  Widget _buildModeSegment(BuildContext context) {
    final isIncome = _showIncome;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildModeSegmentItem(
            context,
            selected: !isIncome,
            icon: FontAwesomeIcons.arrowUp,
            label: 'Pengeluaran',
            activeColor: Colors.red[700]!,
            onTap: () => setState(() => _showIncome = false),
          ),
          _buildModeSegmentItem(
            context,
            selected: isIncome,
            icon: FontAwesomeIcons.arrowDown,
            label: 'Pemasukan',
            activeColor: Colors.green[700]!,
            onTap: () => setState(() => _showIncome = true),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentItem(
    BuildContext context, {
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
                size: 13,
                color: selected ? activeColor : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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

  /// Kartu hero ringkasan arus kas: pemasukan, pengeluaran, dan sisa bersih.
  Widget _buildCashFlowHero({
    required double incomeTotal,
    required double expenseTotal,
    required double netFlow,
    required NumberFormat currency,
  }) {
    final isSurplus = netFlow >= 0;
    final rate = incomeTotal > 0 ? netFlow / incomeTotal : 0.0;
    final badgeColor = isSurplus ? Colors.green[700]! : Colors.red[700]!;
    final badgeBg = isSurplus ? Colors.green[50]! : Colors.red[50]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                child: _buildFlowItem(
                  icon: FontAwesomeIcons.arrowDown,
                  label: 'Pemasukan',
                  value: '+ ${currency.format(incomeTotal)}',
                  color: Colors.green[700]!,
                ),
              ),
              Container(width: 1, height: 44, color: Colors.grey[200]),
              Expanded(
                child: _buildFlowItem(
                  icon: FontAwesomeIcons.arrowUp,
                  label: 'Pengeluaran',
                  value: '− ${currency.format(expenseTotal)}',
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
                  isSurplus
                      ? 'Surplus ${(rate * 100).toStringAsFixed(0)}%'
                      : 'Defisit',
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
              currency.format(netFlow),
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

  Widget _buildFlowItem({
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

  /// Pill highlight kategori terbesar bulan ini di bawah chart.
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

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final planProvider = context.read<PlanProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final monthFilter = expenseProvider.selectedMonthFilter;
      final isAll = monthFilter == MonthFilter.all;
      final monthIndex = isAll ? 0 : monthFilter.index + 1;
      final monthExpenses = !isAll
          ? expenseProvider.expenses
              .where((e) => e.date.month == monthIndex && e.date.year == _selectedYear)
              .toList()
          : expenseProvider.expenses
              .where((e) => e.date.year == _selectedYear).toList();
      await PdfExportService.shareReport(
        allExpenses: expenseProvider.allExpenses,
        filteredExpenses: monthExpenses,
        plans: planProvider.plans,
        periodStartDay: settingsProvider.periodStartDay,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    }
  }

  List<String> get _shortMonths => [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  // ==========================================
  // TAB 2: TAHUNAN (Tren & Riwayat)
  // ==========================================
  Widget _buildYearlyTab(
    BuildContext context,
    ExpenseProvider expenseProvider,
    AnalysisProvider analysisProvider,
    PlanProvider planProvider,
  ) {
    final year = _selectedYear;
    final prevYear = year - 1;
    final monthlyExpenses = analysisProvider.getMonthlyExpenseTotals(year);
    final monthlyIncomes = analysisProvider.getMonthlyIncomeTotals(year);
    final prevExpenses = analysisProvider.getMonthlyExpenseTotals(prevYear);
    final prevIncomes = analysisProvider.getMonthlyIncomeTotals(prevYear);

    final chartData = monthlyExpenses.entries.map((e) {
      return _YearlyChartData(
        month: Constants.months[e.key - 1].substring(0, 3),
        expense: e.value,
        income: monthlyIncomes[e.key] ?? 0,
        monthIndex: e.key,
      );
    }).toList();

    final monthsSoFar = year < DateTime.now().year ? 12 : DateTime.now().month;
    final totalExpenseYear = monthlyExpenses.values.fold(0.0, (sum, v) => sum + v);
    final totalIncomeYear = monthlyIncomes.values.fold(0.0, (sum, v) => sum + v);
    final averageMonthlyExpense =
        monthsSoFar > 0 ? totalExpenseYear / monthsSoFar : 0.0;
    final averageMonthlyIncome =
        monthsSoFar > 0 ? totalIncomeYear / monthsSoFar : 0.0;

    final activeExpenseMonths =
        monthlyExpenses.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final highestMonth =
        activeExpenseMonths.isNotEmpty ? activeExpenseMonths.first : null;

    // YoY comparison
    final prevTotalExpense = prevExpenses.values.fold(0.0, (sum, v) => sum + v);
    final prevTotalIncome = prevIncomes.values.fold(0.0, (sum, v) => sum + v);
    final expenseChange = prevTotalExpense > 0
        ? ((totalExpenseYear - prevTotalExpense) / prevTotalExpense * 100)
        : 0.0;
    final incomeChange = prevTotalIncome > 0
        ? ((totalIncomeYear - prevTotalIncome) / prevTotalIncome * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildYearPicker(context),
          const SizedBox(height: 16),
          if (year < DateTime.now().year)
            _buildYoYComparison(context, expenseChange, incomeChange),
          if (year < DateTime.now().year) const SizedBox(height: 16),
          _buildYearlyChartSection(context, chartData),
          const SizedBox(height: 20),
          _buildCashFlowChart(context, chartData),
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
            year,
          ),
          const SizedBox(height: 24),
          _buildGoalsSummary(context, planProvider, expenseProvider),
          const SizedBox(height: 40),
        ].animate(interval: 50.ms).fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
      ),
    );
  }

  Widget _buildYearPicker(BuildContext context) {
    final now = DateTime.now().year;
    final isCurrentYear = _selectedYear == now;
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol tahun sebelumnya
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _selectedYear > 2020
                ? () => setState(() => _selectedYear--)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Tahun Laporan',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                  ),
                ),
                // Tombol cepat kembali ke tahun berjalan
                if (!isCurrentYear) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _selectedYear = now),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tahun Ini',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Tombol tahun berikutnya
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _selectedYear < now
                ? () => setState(() => _selectedYear++)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoYComparison(BuildContext context, double expenseChange, double incomeChange) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pertumbuhan Tahunan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'vs ${_selectedYear - 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildChangeBadge(
                  'Pengeluaran',
                  expenseChange,
                  // Naik = buruk untuk pengeluaran
                  invertMeaning: true,
                ),
              ),
              Container(width: 1, height: 52, color: Colors.grey[200]),
              Expanded(
                child: _buildChangeBadge(
                  'Pemasukan',
                  incomeChange,
                  // Naik = baik untuk pemasukan
                  invertMeaning: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge tren YoY: warna mengikuti makna (naik belum tentu baik).
  Widget _buildChangeBadge(
    String label,
    double change, {
    required bool invertMeaning,
  }) {
    final isUp = change > 0;
    final isDown = change < 0;
    // Untuk pengeluaran: naik = merah (buruk). Untuk pemasukan sebaliknya.
    final isGood = invertMeaning ? isDown : isUp;
    final isBad = invertMeaning ? isUp : isDown;
    final trendColor =
        isGood
            ? Colors.green[700]!
            : (isBad ? Colors.red[700]! : Colors.grey[500]!);
    final trendBg =
        isGood
            ? Colors.green[50]!
            : (isBad ? Colors.red[50]! : Colors.grey[100]!);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: trendBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp
                    ? Icons.trending_up_rounded
                    : (isDown
                        ? Icons.trending_down_rounded
                        : Icons.remove_rounded),
                size: 16,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${change.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper untuk data Donut Chart
  List<ChartData> _prepareChartData(AnalysisProvider provider) {
    final categoryData = provider.getCategoryDataForChart();
    final chartData = <ChartData>[];

    categoryData.forEach((category, amount) {
      if (amount > 0) {
        final color = Constants.getCategoryStyle(category).color;
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
        final color = Constants.getCategoryStyle(category).color;
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

  /// Kartu empty state saat kategori bulan ini masih kosong.
  Widget _buildEmptyCategoryCard({
    required String message,
    required FaIconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, size: 24, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCategoryBreakdown(
    BuildContext context,
    ExpenseProvider expenseProvider,
  ) {
    final analysisProvider = context.read<AnalysisProvider>();
    final categoryTotals = analysisProvider.getIncomeCategoryTotals();
    final totalAmount = analysisProvider.filteredIncome;

    if (categoryTotals.isEmpty) {
      return _buildEmptyCategoryCard(
        message: 'Belum ada pemasukan bulan ini',
        icon: FontAwesomeIcons.wallet,
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
          final color = style.color;
          final icon = style.icon;

          final catTransactions = expenseProvider.expenses
              .where((e) => e.category == categoryName && e.type == 'income')
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return GestureDetector(
            key: ValueKey(categoryName),
            onTap: () {
              // Drill-down: tampilkan seluruh transaksi kategori ini
              // dalam bottom sheet detail.
              CategoryDetailBottomSheet.show(
                context,
                categoryName: categoryName,
                transactions: catTransactions,
                type: 'income',
                periodLabel: analysisProvider.currentMonthYear,
                categoryTotal: amount,
                grandTotal: totalAmount,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: FaIcon(icon, color: color, size: 19),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormatter.format(amount),
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
                      color: color,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${(percent * 100).toStringAsFixed(1)}% dari total pemasukan',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildYearlyChartSection(BuildContext context, List<_YearlyChartData> data) {
    final now = DateTime.now();
    final currentMonth = now.month;
    // Gunakan 6-12 bulan terakhir untuk forecast
    final window = data.length.clamp(6, 12);
    final netData = data.sublist(data.length - window).map((d) {
      final net = d.income - d.expense;
      return d.income > 0 || d.expense > 0 ? net : 0.0;
    }).toList();
    final forecastVals = forecastMonths(netData, 3);
    final chartData = data.map((d) => _YearlyChartData(
      month: d.month, income: d.income, expense: d.expense, monthIndex: d.monthIndex,
    )).toList();
    // Gabungkan forecast ke dalam list dengan label "Proyeksi"
    final forecastLabels = ['F+1', 'F+2', 'F+3'];
    final hasData = netData.any((v) => v != 0);

    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
          const Text(
            "Arus Kas per Bulan",
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
              if (hasData) _legendPill(Colors.indigo, 'Proyeksi'),
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
              series: <CartesianSeries>[
                ColumnSeries<_YearlyChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (_YearlyChartData d, _) => d.month,
                  yValueMapper: (_YearlyChartData d, _) => d.income,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.green[500],
                  spacing: 0.25,
                  width: 0.35,
                ),
                ColumnSeries<_YearlyChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (_YearlyChartData d, _) => d.month,
                  yValueMapper: (_YearlyChartData d, _) => d.expense,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.red[400],
                  spacing: 0.25,
                  width: 0.35,
                ),
                if (hasData)
                  SplineSeries<_ForecastData, String>(
                    dataSource: List.generate(3, (i) => _ForecastData(
                      label: forecastLabels[i],
                      value: forecastVals[i].clamp(0, double.infinity),
                    )),
                    xValueMapper: (_ForecastData d, _) => d.label,
                    yValueMapper: (_ForecastData d, _) => d.value,
                    color: Colors.indigo,
                    width: 2,
                    dashArray: [6, 3],
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      color: Colors.indigo,
                      width: 6,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(fontSize: 9, color: Colors.indigo),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Legenda berbentuk pill untuk kartu grafik.
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

  Widget _buildCashFlowChart(BuildContext context, List<_YearlyChartData> data) {
    double cumulative = 0;
    final cashData = data.map((d) {
      cumulative += d.income - d.expense;
      return _CashFlowData(
        month: d.month,
        net: d.income - d.expense,
        cumulative: cumulative,
      );
    }).toList();

    final primary = Theme.of(context).primaryColor;
    return Container(
      height: 270,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
          const Text(
            'Tren Kas Kumulatif',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pertumbuhan saldo bersih dari bulan ke bulan',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _legendPill(Colors.teal[600]!, 'Net bulanan'),
              _legendPill(primary, 'Kumulatif'),
            ],
          ),
          const SizedBox(height: 8),
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
              primaryYAxis: NumericAxis(isVisible: false),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries<_CashFlowData, String>>[
                ColumnSeries<_CashFlowData, String>(
                  dataSource: cashData,
                  xValueMapper: (d, _) => d.month,
                  yValueMapper: (d, _) => d.net,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  color: Colors.teal,
                  spacing: 0.35,
                  width: 0.45,
                  pointColorMapper: (d, _) => d.net >= 0 ? Colors.teal[400] : Colors.red[300],
                ),
                SplineAreaSeries<_CashFlowData, String>(
                  dataSource: cashData,
                  xValueMapper: (d, _) => d.month,
                  yValueMapper: (d, _) => d.cumulative,
                  color: primary,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primary.withValues(alpha: 0.35),
                      primary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderColor: primary,
                  borderWidth: 2.5,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    color: Colors.white,
                    borderColor: primary,
                    borderWidth: 2,
                    width: 8,
                    height: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(value),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    int year,
  ) {
    final currentMonth = year < DateTime.now().year ? 12 : DateTime.now().month;
    final activeMonths = monthlyExpenses.keys.where((m) => m <= currentMonth).toList();
    activeMonths.sort((a, b) => b.compareTo(a));

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

            final isSurplusMonth = saving >= 0;
            final statusColor =
                isSurplusMonth ? Colors.teal[700]! : Colors.orange[800]!;
            final statusBg =
                isSurplusMonth ? Colors.teal[50]! : Colors.orange[50]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final monthExpenses = provider.allExpenses
                      .where((e) =>
                          e.date.month == month && e.date.year == year)
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Constants.months[month - 1].substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Out: ${compactFormat.format(expense)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'In: ${compactFormat.format(income)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSurplusMonth
                                                ? Icons.savings_rounded
                                                : Icons.warning_rounded,
                                            size: 11,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isSurplusMonth
                                                ? 'Surplus ${compactFormat.format(saving)}'
                                                : 'Defisit ${compactFormat.format(saving.abs())}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (month > 1) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        isHigher
                                            ? Icons.trending_up_rounded
                                            : (isSaving
                                                ? Icons.trending_down_rounded
                                                : Icons.remove_rounded),
                                        size: 14,
                                        color: isHigher
                                            ? Colors.red[400]
                                            : (isSaving
                                                ? Colors.green[600]
                                                : Colors.grey[400]),
                                      ),
                                    ],
                                  ],
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

    if (categoryTotals.isEmpty) {
      return _buildEmptyCategoryCard(
        message: 'Belum ada pengeluaran bulan ini',
        icon: FontAwesomeIcons.basketShopping,
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
          final color = style.color;
          final icon = style.icon;

          // Transaksi dalam kategori ini
          final catTransactions = expenseProvider.expenses
              .where((e) => e.category == categoryName && e.type == 'expense')
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final percentCaption =
              budget != null
                  ? '${(progress * 100).toStringAsFixed(0)}% dari anggaran'
                  : '${(progress * 100).toStringAsFixed(1)}% dari total pengeluaran';

          return GestureDetector(
            key: ValueKey(categoryName),
            onTap: () {
              // Drill-down: tampilkan seluruh transaksi kategori ini
              // dalam bottom sheet detail.
              CategoryDetailBottomSheet.show(
                context,
                categoryName: categoryName,
                transactions: catTransactions,
                type: 'expense',
                periodLabel: analysisProvider.currentMonthYear,
                categoryTotal: spentAmount,
                grandTotal: totalAmount,
                budgetLimit: budget?.limitAmount as double?,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: FaIcon(icon, color: color, size: 19),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
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
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      color: budget != null ? progressColor : color,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      percentCaption,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
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

class _ForecastData {
  final String label;
  final double value;

  _ForecastData({required this.label, required this.value});
}

class _CashFlowData {
  final String month;
  final double net;
  final double cumulative;

  _CashFlowData({
    required this.month,
    required this.net,
    required this.cumulative,
  });
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
