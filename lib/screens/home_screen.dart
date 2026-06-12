import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import '../providers/analysis_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_tap.dart';
import '../services/notification_service.dart';
import '../utils/financial_health.dart';
import '../utils/period_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showKekayaanMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Consumer3<ExpenseProvider, PlanProvider, SettingsProvider>(
            builder: (context, provider, planProvider, settings, child) {
              final hasActiveFilter =
                  provider.selectedCategory != 'Semua Kategori' ||
                  provider.selectedMonthFilter != MonthFilter.all ||
                  provider.startDate != null;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. AppBar simpel (hanya judul saat collapsed)
                  SliverAppBar(
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    expandedHeight: 56.0, // Hanya tinggi toolbar standar
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    title: const Text(
                      'Ringkasan',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // 2. Hero Card — di luar SliverAppBar agar shadow tidak ter-clip
                  SliverToBoxAdapter(
                    child: Padding(
                      // Padding atas tipis, bawah cukup untuk shadow (20px)
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: _buildHeroCard(context, provider, planProvider, settings),
                    ),
                  ),

                  // 2b. Financial Health Scorecard
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _buildHealthScorecard(context),
                    ),
                  ),

                  // 3. Sticky Filter Bar
                  // 3. STICKY HEADER (Filter Icon + Month Badges)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyFilterDelegate(
                      minHeight: 60.0,
                      maxHeight: 60.0,
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
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
                                icon: const FaIcon(
                                  FontAwesomeIcons.sliders,
                                  size: 18,
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
                                provider: provider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: provider.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => provider.setSearchQuery(''),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (v) => provider.setSearchQuery(v),
                      ),
                    ),
                  ),

                  // 5. List Transaksi
                  _buildGroupedExpenseList(context, provider),

                  // Padding bawah untuk FAB
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ExpenseProvider provider,
    PlanProvider planProvider,
    SettingsProvider settings,
  ) {
    final showKekayaan = _showKekayaanMode;
    final hideAmount = settings.hideAmount;
    final analysisProvider = context.read<AnalysisProvider>();
    final payDay = settings.periodStartDay;
    final usePeriod = payDay > 1;

    final flowIncome = usePeriod
        ? analysisProvider.getPeriodIncome(payDay)
        : provider.totalIncome;
    final flowExpenses = usePeriod
        ? analysisProvider.getPeriodExpenses(payDay)
        : provider.totalExpenses;
    final flowBalance = flowIncome - flowExpenses;

    final allTimeBal = analysisProvider.allTimeBalance;
    final totalGoals =
        planProvider.plans.fold<double>(0, (sum, p) => sum + p.currentAmount);
    final totalWealth = allTimeBal + totalGoals;

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
    String displayAmount;
    Widget bottomSection;

    if (showKekayaan) {
      heroTitle = 'Total Kekayaan';
      displayAmount = hideAmount
          ? 'Rp •••••'
          : currencyFormat.format(totalWealth);
      bottomSection = Row(
        children: [
          _rowItem(
            icon: FontAwesomeIcons.moneyBillWave,
            label: 'Arus Kas',
            amount: flowBalance,
            color: flowBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
            hideAmount: hideAmount,
            compactFormat: compactFormat,
          ),
          const SizedBox(width: 16),
          _rowItem(
            icon: FontAwesomeIcons.piggyBank,
            label: 'Ditabung',
            amount: totalGoals,
            color: Colors.amberAccent,
            hideAmount: hideAmount,
            compactFormat: compactFormat,
          ),
        ],
      );
    } else {
      heroTitle = 'Uang Saya';
      displayAmount = hideAmount
          ? 'Rp •••••'
          : currencyFormat.format(allTimeBal);
      bottomSection = Row(
        children: [
          _rowItem(
            icon: FontAwesomeIcons.arrowDown,
            label: 'Pemasukan',
            amount: flowIncome,
            color: Colors.greenAccent,
            hideAmount: hideAmount,
            compactFormat: compactFormat,
          ),
          const SizedBox(width: 16),
          _rowItem(
            icon: FontAwesomeIcons.arrowUp,
            label: 'Pengeluaran',
            amount: flowExpenses,
            color: Colors.redAccent,
            hideAmount: hideAmount,
            compactFormat: compactFormat,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heroTitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _showKekayaanMode = !_showKekayaanMode),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.arrowsRotate,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Balance + Eye
          Row(
            children: [
              Text(
                displayAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => settings.setHideAmount(!hideAmount),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(
                    hideAmount
                        ? FontAwesomeIcons.eyeSlash
                        : FontAwesomeIcons.eye,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Colors.white.withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: 12),
          bottomSection,
        ],
      ),
    );
  }

  Widget _rowItem({
    required FaIconData icon,
    required String label,
    required double amount,
    required bool hideAmount,
    required NumberFormat compactFormat,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.blue[200], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              FaIcon(
                icon,
                color: color.withValues(alpha: 0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                hideAmount ? 'Rp •••••' : compactFormat.format(amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScorecard(BuildContext context) {
    final analysisProvider = context.read<AnalysisProvider>();
    final allTimeIncome = analysisProvider.allTimeIncome;
    final allTimeExpenses = analysisProvider.allTimeExpenses;
    final totalSavings = analysisProvider.totalSavingsAllTime;
    final incomeMap = analysisProvider.getMonthlyIncomeTotals(DateTime.now().year);
    final monthlyIncomes = List.generate(12, (i) {
      return incomeMap[i + 1] ?? 0.0;
    });

    // Hitung budget hit rate dari expenseProvider langsung
    final budgetHitRate = 0;
    final totalBudgets = 0;

    final health = calculateFinancialHealth(
      totalIncome: allTimeIncome,
      totalExpenses: allTimeExpenses,
      totalSavings: totalSavings,
      budgetsHit: budgetHitRate,
      totalBudgets: totalBudgets,
      monthlyIncomes: monthlyIncomes,
    );

    final gradeColors = {
      'A': const Color(0xFF2ECC71),
      'B': const Color(0xFF27AE60),
      'C': const Color(0xFFF39C12),
      'D': const Color(0xFFE67E22),
      'E': const Color(0xFFE74C3C),
    };
    final color = gradeColors[health.grade] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Text(
                health.grade,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
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
                      'Skor Keuangan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        health.label,
                        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${health.score}/100',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        health.advice,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: List Transaksi Model Kartu Harian (REVAMP TOTAL)
  // WIDGET: List Transaksi dengan Gaya Kartu Terpisah (Monthly Report Style)
  Widget _buildGroupedExpenseList(
    BuildContext context,
    ExpenseProvider provider,
  ) {
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
                child: FaIcon(
                  FontAwesomeIcons.fileInvoiceDollar,
                  size: 40,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
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
          final dailyIncome = expenses
              .where((e) => e.type == 'income')
              .fold(0.0, (sum, e) => sum + e.amount);
          final dailyExpense = expenses
              .where((e) => e.type == 'expense')
              .fold(0.0, (sum, e) => sum + e.amount);

          final runningBalances =
              context.read<AnalysisProvider>().getRunningBalances();
          final hideAmount = context.read<SettingsProvider>().hideAmount;

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
                            color: Theme.of(context).colorScheme.primary,
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
                    // Ringkasan Harian (Income & Expense)
                    Row(
                      children: [
                        if (dailyIncome > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[100]!),
                            ),
                            child: Text(
                              '+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(dailyIncome)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        if (dailyExpense > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Text(
                              '-${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(dailyExpense)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // B. LIST ITEM (Individual Cards)
              ...expenses.map((expense) {
                final after = runningBalances[expense.id] ?? 0.0;
                return _buildExpenseCard(context, expense, provider, after, hideAmount);
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
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
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
    double runningBalance,
    bool hideAmount,
  ) {
    final style = Constants.getCategoryStyle(expense.category);
    final color = style['color'] as Color;
    final icon = style['icon'];

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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: FaIcon(icon, color: color, size: 20)),
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

                // 3. Nominal + Running Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hideAmount
                          ? 'Rp •••••'
                          : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(runningBalance),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: runningBalance >= 0
                            ? Colors.grey[500]
                            : Colors.red[400],
                      ),
                    ),
                    if (!hideAmount)
                      Icon(
                        Icons.arrow_upward,
                        size: 10,
                        color: runningBalance >= 0
                            ? Colors.grey[400]
                            : Colors.red[300],
                      ),
                    if (!hideAmount) const SizedBox(height: 1),
                    Text(
                      (expense.type == 'income' ? '+ ' : '- ') +
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(expense.amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color:
                            expense.type == 'income'
                                ? Colors.green[700]
                                : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                      expenseProvider.editExpense(updatedExpense, sttCategory: expense.category),
            ),
      ),
    );
  }

  void _showExpenseOptions(BuildContext context, Expense expense) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
    final balances = analysisProvider.getRunningBalances();
    final after = balances[expense.id] ?? 0.0;
    final before = after - (expense.type == 'income' ? expense.amount : -expense.amount);
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
    final icon = style['icon'];

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
                      child: Center(
                        child: FaIcon(icon, color: color, size: 24),
                      ),
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
                            maxLines: 3,
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

                const SizedBox(height: 20),

                // 3. Running Balance
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Sebelum',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(before),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Saldo Sesudah',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(after),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: after >= 0
                                    ? Colors.black87
                                    : Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Tombol Edit
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

                // 5. Tombol Hapus
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
