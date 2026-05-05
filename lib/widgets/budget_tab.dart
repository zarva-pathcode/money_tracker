import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_item.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import 'add_budget_bottom_sheet.dart';
import 'animated_tap.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProvider, expenseProvider, _) {
        final budgets = budgetProvider.budgets;
        final currentExpenses = expenseProvider.allExpenses;
        final currentMonth = DateTime.now().month;
        final currentYear = DateTime.now().year;

        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada anggaran yang dibuat.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        double totalBudget = 0;
        double totalSpent = 0;

        for (var budget in budgets) {
          totalBudget += budget.limitAmount;
          double categorySpent = 0;
          for (var expense in currentExpenses) {
            if (expense.category == budget.category && 
                expense.date.month == currentMonth && 
                expense.date.year == currentYear &&
                expense.type == 'expense') { 
              categorySpent += expense.amount;
            }
          }
          totalSpent += categorySpent;
        }

        double overallProgress = totalBudget > 0 ? totalSpent / totalBudget : 0;
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
                    colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Terpakai", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(totalSpent),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' / ${currencyFormat.format(totalBudget)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        ),
                        FractionallySizedBox(
                          widthFactor: overallProgress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: overallProgress > 0.85 ? Colors.redAccent : (overallProgress > 0.5 ? Colors.orangeAccent : Colors.white), 
                              borderRadius: BorderRadius.circular(4)
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('${(overallProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final budget = budgets[index];
                    
                    double spentAmount = 0;
                    for (var expense in currentExpenses) {
                      if (expense.category == budget.category && 
                          expense.date.month == currentMonth && 
                          expense.date.year == currentYear &&
                          expense.type == 'expense') { 
                        spentAmount += expense.amount;
                      }
                    }

                    return _buildBudgetCard(context, budget, spentAmount);
                  },
                  childCount: budgets.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetItem budget, double spentAmount) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 1,
    );

    // Find category icon/color
    final categoryName = Constants.expenseCategories.firstWhere(
      (c) => c == budget.category,
      orElse: () => budget.category,
    );
    final categoryData = Constants.getCategoryStyle(categoryName);

    double progress = spentAmount / budget.limitAmount;
    if (progress > 1.0) progress = 1.0;

    // Color logic: Green (<50%), Yellow (50-85%), Red (>85%)
    Color progressColor = Colors.green;
    if (progress >= 0.85) {
      progressColor = Colors.red;
    } else if (progress >= 0.5) {
      progressColor = Colors.orange;
    }

    return AnimatedTap(
      onTap: () {
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
                  color: (categoryData['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FaIcon(categoryData['icon'], color: categoryData['color'] as Color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limit: ${currencyFormat.format(budget.limitAmount)} / Bln',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton( // Delete budget button
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                   _showDeleteDialog(context, budget);
                },
                tooltip: 'Hapus Anggaran',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              color: progressColor,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: ${currencyFormat.format(spentAmount)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: progressColor),
              ),
              Text(
                'Sisa: ${currencyFormat.format(budget.limitAmount - spentAmount < 0 ? 0 : budget.limitAmount - spentAmount)}',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  void _showDeleteDialog(BuildContext context, BudgetItem budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anggaran?'),
        content: Text('Apakah Anda yakin ingin menghapus anggaran untuk ${budget.category}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<BudgetProvider>(context, listen: false).deleteBudget(budget.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anggaran dihapus')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
