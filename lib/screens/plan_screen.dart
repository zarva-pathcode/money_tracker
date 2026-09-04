import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plan_item.dart';
import '../providers/plan_provider.dart';
import '../widgets/add_fund_bottom_sheet.dart';
import '../widgets/withdraw_fund_bottom_sheet.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_tab.dart';
import '../widgets/animated_tap.dart';
import 'add_plan_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 0; // Budget first
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBudgetBottomSheet(),
    );
  }

  void _confirmDeletePlan(BuildContext context, PlanItem plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Target?'),
        content: Text('Yakin ingin menghapus target "${plan.title}"? Saldo yang sudah terkumpul tidak akan berubah di rekap transaksi, hanya target ini yang dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<PlanProvider>(context, listen: false).deletePlan(plan.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlanOptions(BuildContext context, PlanItem plan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const FaIcon(FontAwesomeIcons.penToSquare, size: 18),
                title: const Text('Edit Target Impian'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPlanScreen(planToEdit: plan)),
                  );
                },
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const FaIcon(FontAwesomeIcons.trashCan, size: 18, color: Colors.red),
                title: const Text('Hapus Target', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePlan(context, plan);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                backgroundColor: Colors.grey[50],
                elevation: 0,
                pinned: true,
                floating: true,
                automaticallyImplyLeading: false,
                title: const Text(
                  'Perencanaan',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.plus,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _showAddBudgetSheet(context);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPlanScreen(),
                            ),
                          );
                        }
                      },
                      tooltip: _tabController.index == 0 ? 'Buat Anggaran' : 'Buat Target',
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(72),
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.grey[500],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [Tab(text: "Anggaran"), Tab(text: "Target Impian")],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              const BudgetTab(),
              _buildGoalsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsTab(BuildContext context) {
    return Consumer<PlanProvider>(
      builder: (context, planProvider, _) {
        final plans = planProvider.plans;

        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.piggyBank,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Belum ada target tabungan.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai rencanakan masa depanmu sekarang.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPlanScreen(),
                      ),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Buat Target Pertama', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
          );
        }

        double totalTarget = 0;
        double totalCollected = 0;
        int activeCount = 0;
        int completedCount = 0;

        for (var p in plans) {
          totalTarget += p.targetAmount;
          totalCollected += p.currentAmount;
          if (p.progressPercentage >= 1.0) {
            completedCount++;
          } else {
            activeCount++;
          }
        }

        double overallProgress = totalTarget > 0 ? totalCollected / totalTarget : 0;
        if (overallProgress > 1.0) overallProgress = 1.0;

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

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Tabungan",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(overallProgress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(totalCollected),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'dari target ${currencyFormat.format(totalTarget)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[100],
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildQuickStat(context, '${plans.length}', 'Semua', FontAwesomeIcons.bullseye, Colors.blue),
                        const SizedBox(width: 12),
                        _buildQuickStat(context, '$activeCount', 'Aktif', FontAwesomeIcons.spinner, Colors.orange),
                        const SizedBox(width: 12),
                        _buildQuickStat(context, '$completedCount', 'Tercapai', FontAwesomeIcons.check, Colors.green),
                      ],
                    )
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plan = plans[index];
                    return _buildGoalCard(context, plan, currencyFormat, compactFormat)
                        .animate(delay: (index * 50).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
                  },
                  childCount: plans.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildQuickStat(BuildContext context, String value, String label, dynamic icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 16, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, PlanItem plan, NumberFormat currencyFormat, NumberFormat compactFormat) {
    final isCompleted = plan.progressPercentage >= 1.0;
    final shortage = plan.targetAmount - plan.currentAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: plan.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: FaIcon(plan.icon, color: plan.color, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.circleCheck, size: 10, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Target Tercapai', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        Text(
                          'Kurang ${compactFormat.format(shortage)} lagi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16, color: Colors.grey),
                  onPressed: () => _showPlanOptions(context, plan),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(plan.currentAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      currencyFormat.format(plan.targetAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.progressPercentage,
                    backgroundColor: Colors.grey[100],
                    color: isCompleted ? Colors.green : plan.color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Row(
            children: [
              if (plan.currentAmount > 0)
                Expanded(
                  flex: 1,
                  child: AnimatedTap(
                    onTap: () => _showWithdrawDialog(context, plan),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFFF5F5F5))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text('Tarik', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: AnimatedTap(
                  onTap: () => _showAddFundDialog(context, plan),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, size: 18, color: plan.color),
                        const SizedBox(width: 8),
                        Text('Tambah Saldo', style: TextStyle(color: plan.color, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddFundDialog(BuildContext context, PlanItem plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFundBottomSheet(plan: plan),
    );
  }

  void _showWithdrawDialog(BuildContext context, PlanItem plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawFundBottomSheet(plan: plan),
    );
  }
}
