import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plan_item.dart';
import '../providers/plan_provider.dart';
import '../widgets/add_fund_bottom_sheet.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_tab.dart';
import '../widgets/animated_tap.dart';
import 'add_plan_screen.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                // systemOverlayStyle: SystemUiOverlayStyle.dark,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                pinned: true,
                floating: true,
                automaticallyImplyLeading: false,
                title: const Text(
                  'Tabungan Impian',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.plus,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () {
                        final tabIndex = DefaultTabController.of(context).index;
                        if (tabIndex == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPlanScreen(),
                            ),
                          );
                        } else {
                          _showAddBudgetSheet(context);
                        }
                      },
                      tooltip: 'Buat Baru',
                    ),
                  ),
                ],
                bottom: TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [Tab(text: "Goals"), Tab(text: "Budget")],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // TAB 1: GOALS
              Consumer<PlanProvider>(
                builder: (context, planProvider, _) {
                  final plans = planProvider.plans;

                  if (plans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.piggyBank,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada target tabungan.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  double totalTarget = 0;
                  double totalCollected = 0;
                  for (var p in plans) {
                    totalTarget += p.targetAmount;
                    totalCollected += p.currentAmount;
                  }

                  double overallProgress =
                      totalTarget > 0 ? totalCollected / totalTarget : 0;
                  if (overallProgress > 1.0) overallProgress = 1.0;

                  final currencyFormat = NumberFormat.compactCurrency(
                    locale: 'id_ID',
                    symbol: 'Rp',
                    decimalDigits: 1,
                  );

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Terkumpul",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(totalCollected),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ' / ${currencyFormat.format(totalTarget)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: overallProgress,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(overallProgress * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final plan = plans[index];
                            return _buildPlanCard(context, plan);
                          }, childCount: plans.length),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // TAB 2: BUDGET (Placeholder for now)
              _buildBudgetTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetTab() {
    return const BudgetTab();
  }

  void _showAddBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBudgetBottomSheet(),
    );
  }

  Widget _buildPlanCard(BuildContext context, PlanItem plan) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 1,
    );

    return AnimatedTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPlanScreen(planToEdit: plan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.03),
              offset: const Offset(0, 5),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: plan.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: FaIcon(plan.icon, color: plan.color, size: 22),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(plan.progressPercentage * 100).toStringAsFixed(1)}% Terkumpul',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.circlePlus,
                    color: Colors.black54,
                  ),
                  onPressed: () => _showAddFundDialog(context, plan),
                  tooltip: 'Tambah Saldo',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: plan.progressPercentage,
                backgroundColor: Colors.grey[100],
                color: plan.color,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(plan.currentAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  currencyFormat.format(plan.targetAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFundDialog(BuildContext context, PlanItem plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddFundBottomSheet(plan: plan);
      },
    );
  }
}
