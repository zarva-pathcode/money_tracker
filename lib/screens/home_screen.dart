import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/models/expense.dart';
import 'package:money_tracker/screens/edit_expense_screen.dart';
import 'package:money_tracker/utils/constants.dart';
import 'package:money_tracker/widgets/filter_bottom_sheet.dart';
import 'package:money_tracker/widgets/month_filter_selector.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_tap.dart';
import '../widgets/today_budget_card.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showKekayaanMode = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  /// Auto-center viewport ke search bar dengan SATU animasi mulus.
  /// Offset dihitung presisi via [RenderAbstractViewport.getOffsetToReveal]
  /// dikurangi tinggi header sticky — tanpa jumpTo/animasi ganda pemicu glitch.
  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus) return;
    // Tunda hingga keyboard + spacer selesai layout agar geometry valid.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !_scrollController.hasClients) return;
      final targetCtx = _searchBarKey.currentContext;
      if (targetCtx == null || !targetCtx.mounted) return;
      final renderObject = targetCtx.findRenderObject();
      if (renderObject == null) return;
      const stickyHeaderHeight = 116.0; // AppBar 56 + filter sticky 60
      final revealed = RenderAbstractViewport.of(
        renderObject,
      ).getOffsetToReveal(renderObject, 0.0);
      final max = _scrollController.position.maxScrollExtent;
      final target = (revealed.offset - stickyHeaderHeight).clamp(0.0, max);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sapaan dinamis berdasarkan jam: Pagi / Siang / Sore / Malam.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    // Tanpa Scaffold ganda — keyboard insets dikelola satu pintu oleh
    // Scaffold di MainScreen agar tidak terjadi perhitungan ganda.
    return Stack(
      children: [
          Consumer3<ExpenseProvider, PlanProvider, SettingsProvider>(
            builder: (context, provider, planProvider, settings, child) {
              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. AppBar sapaan dinamis + tanggal hari ini
                  SliverAppBar(
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    expandedHeight: 56.0, // Hanya tinggi toolbar standar
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    centerTitle: false, // Judul rata kiri
                    titleSpacing: 20,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      // Badge jumlah transaksi bulan berjalan
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${provider.expenses.length} transaksi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Hero Card — di luar SliverAppBar agar shadow tidak ter-clip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: _buildHeroCard(context, provider, planProvider, settings),
                    ),
                  ),

                  // 2b. Smart Daily Budget Allowance Card
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: TodayBudgetCard(),
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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
                      key: _searchBarKey,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        // Scroll otomatis bawaan Flutter saat fokus: tempatkan
                        // search bar 130px dari atas (di bawah AppBar 56 +
                        // filter sticky 60) dalam 1 transisi mulus sinkron
                        // dengan naiknya keyboard — tanpa animasi manual ganda.
                        scrollPadding: const EdgeInsets.only(
                          top: 130.0,
                          bottom: 20.0,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: provider.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  tooltip: 'Batalkan pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setSearchQuery('');
                                    _searchFocusNode.unfocus();
                                  },
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

                  // 6. Spacer dinamis setinggi keyboard — menambah ruang
                  // scroll saat keyboard terbuka walau item sedikit/kosong,
                  // sehingga search bar selalu bisa digeser ke atas.
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom,
                    ),
                  ),

                  // Padding bawah untuk FAB
                ],
              );
            },
          ),
        ],
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
          // Pill switcher mode saldo: Uang Saya / Total Kekayaan
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildHeroModeItem(
                  selected: !showKekayaan,
                  label: 'Uang Saya',
                  onTap: () => setState(() => _showKekayaanMode = false),
                ),
                _buildHeroModeItem(
                  selected: showKekayaan,
                  label: 'Total Kekayaan',
                  onTap: () => setState(() => _showKekayaanMode = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            heroTitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
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
      // Animasi masuk sekali jalan (tanpa infinite loop hemat CPU/baterai).
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(
      begin: 0.08,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOutQuad,
    );
  }

  /// Item pill switcher mode saldo di hero card (putih transparan).
  Widget _buildHeroModeItem({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
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
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FaIcon(
                  FontAwesomeIcons.fileInvoiceDollar,
                  size: 40,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
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
    // Padding bawah 100 agar item terakhir tidak tertutup navbar/FAB.
    // Saat keyboard terbuka navbar/FAB disembunyikan (main_screen),
    // jadi padding dikecilkan agar tidak ada ruang kosong besar.
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, keyboardVisible ? 20 : 100),
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
              }),
            ],
          );
        }, childCount: sortedKeys.length),
      ),
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
    final color = style.color;
    final icon = style.icon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Jarak antar kartu
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Radius membulat
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 12,
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
                    color: color.withValues(alpha: 0.12),
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
    final color = style.color;
    final icon = style.icon;

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

                // 2. Header: ikon besar + judul + badge waktu + nominal
                Row(
                  children: [
                    // Ikon Kategori
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: FaIcon(icon, color: color, size: 26),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Badge waktu
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              dateString,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nominal besar dengan tanda +/− sesuai tipe
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${expense.type == 'income' ? '+' : '−'} ${currencyFormatter.format(expense.amount)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color:
                          expense.type == 'income'
                              ? Colors.green[700]
                              : Colors.red[700],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Kartu dampak ke saldo (Sebelum ➔ Sesudah)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dampak ke Saldo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sebelum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormatter.format(before),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Sesudah',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormatter.format(after),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: after >= 0
                                        ? Theme.of(context).primaryColor
                                        : Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Tombol aksi berdampingan: Edit + Hapus
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditExpense(context, expense);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text("Edit"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(context, provider, expense.id);
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red[600],
                          size: 18,
                        ),
                        label: Text(
                          "Hapus",
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
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
