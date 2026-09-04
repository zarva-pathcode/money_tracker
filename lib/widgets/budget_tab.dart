import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_item.dart';
import '../providers/budget_provider.dart';
import '../utils/constants.dart';
import 'add_budget_bottom_sheet.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, _) {
        final budgets = budgetProvider.budgets;

        // -------- Empty State --------
        if (budgets.isEmpty) {
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
                  child: const FaIcon(FontAwesomeIcons.chartPie, size: 60, color: Color(0xFF6366F1)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Belum ada anggaran yang dibuat.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Atur batas pengeluaran per kategori untuk mengendalikan keuanganmu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddBudgetBottomSheet(),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Buat Anggaran Pertama', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
          );
        }

        final totalBudget = budgetProvider.totalBudget;
        final totalSpent = budgetProvider.totalSpent;
        final overallProgress = budgetProvider.overallProgress;

        final currencyFormat = NumberFormat.compactCurrency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 1,
        );

        // Aggregate quick stats for cards status
        int safeCount = 0;
        int warningCount = 0;
        int overCount = 0;
        for (final b in budgets) {
          final spent = budgetProvider.spentForCategory(b.category);
          final progress = b.limitAmount > 0 ? (spent / b.limitAmount) : 0;
          final thresholdPct = b.threshold / 100;
          if (progress >= 1.0) {
            overCount++;
          } else if (progress >= thresholdPct) {
            warningCount++;
          } else {
            safeCount++;
          }
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // -------- Hero Card --------
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
                    // Title + Progress Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ringkasan Anggaran",
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
                      currencyFormat.format(totalSpent),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'dari total anggaran ${currencyFormat.format(totalBudget)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[100],
                        color: overallProgress > 0.85 ? Colors.redAccent : (overallProgress > 0.5 ? Colors.orangeAccent : Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quick Stats
                    Row(
                      children: [
                        _buildQuickStat(context, '$safeCount', 'Aman', FontAwesomeIcons.shieldHalved, Colors.green),
                        const SizedBox(width: 12),
                        _buildQuickStat(context, '$warningCount', 'Peringatan', FontAwesomeIcons.triangleExclamation, Colors.orange),
                        const SizedBox(width: 12),
                        _buildQuickStat(context, '$overCount', 'Jebol', FontAwesomeIcons.xmark, Colors.red),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
            ),

            // -------- Budget Cards --------
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final budget = budgets[index];
                    final spentAmount = budgetProvider.spentForCategory(budget.category);
                    return _buildBudgetCard(context, budget, spentAmount)
                        .animate(delay: (index * 50).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
                  },
                  childCount: budgets.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildQuickStat(BuildContext context, String value, String label, dynamic iconData, Color color) {
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
            FaIcon(iconData, size: 16, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetItem budget, double spentAmount) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 1,
    );

    final categoryName = Constants.expenseCategories.firstWhere(
      (c) => c == budget.category,
      orElse: () => budget.category,
    );
    final categoryData = Constants.getCategoryStyle(categoryName);

    double progress = budget.limitAmount > 0 ? (spentAmount / budget.limitAmount) : 0;
    if (progress > 1.0) progress = 1.0;
    final thresholdPct = budget.threshold / 100;

    Color progressColor = Colors.green;
    if (progress >= 1.0) {
      progressColor = Colors.red;
    } else if (progress >= thresholdPct) {
      progressColor = Colors.orange;
    }

    final remaining = budget.limitAmount - spentAmount < 0 ? 0.0 : budget.limitAmount - spentAmount;

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
          // Header: Icon + Info + Menu Options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (categoryData['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FaIcon(
                    categoryData['icon'],
                    color: categoryData['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Limit: ${currencyFormat.format(budget.limitAmount)} / Bln',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Peringatan di ${budget.threshold.toInt()}% • ${budget.granularity == 'monthly' ? 'Bulanan' : (budget.granularity == 'weekly' ? 'Mingguan' : 'Harian')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (progress >= 1.0)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.circleExclamation, size: 10, color: Colors.red),
                              const SizedBox(width: 4),
                              const Text('Anggaran Terlewati', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else if (progress >= thresholdPct)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.triangleExclamation, size: 10, color: Colors.orange),
                              const SizedBox(width: 4),
                              const Text('Peringatan', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Menu Options (Edit / Delete)
                Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.pen, size: 14, color: Colors.grey),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: AddBudgetBottomSheet(budgetToEdit: budget),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16, color: Colors.redAccent),
                      tooltip: 'Hapus',
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () => _showDeleteDialog(context, budget),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terpakai: ${currencyFormat.format(spentAmount)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: progressColor, fontSize: 13),
                    ),
                    Text(
                      'Sisa: ${currencyFormat.format(remaining)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[100],
                    color: progressColor,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      'Limit: ${currencyFormat.format(budget.limitAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
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

  void _showDeleteDialog(BuildContext context, BudgetItem budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Anggaran?'),
        content: Text('Apakah Anda yakin ingin menghapus anggaran untuk kategori "${budget.category}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<BudgetProvider>(context, listen: false).deleteBudget(budget.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Anggaran dihapus'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
