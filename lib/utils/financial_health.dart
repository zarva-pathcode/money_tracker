import 'dart:math';

class FinancialHealthScore {
  final int score;
  final String grade;
  final double savingsRatio;
  final double expenseToIncomeRatio;
  final int budgetHitRate;
  final int totalBudgets;
  final double incomeStability;

  FinancialHealthScore({
    required this.score,
    required this.grade,
    required this.savingsRatio,
    required this.expenseToIncomeRatio,
    required this.budgetHitRate,
    required this.totalBudgets,
    required this.incomeStability,
  });

  String get label {
    switch (grade) {
      case 'A':
        return 'Sangat Sehat';
      case 'B':
        return 'Sehat';
      case 'C':
        return 'Cukup';
      case 'D':
        return 'Kurang';
      case 'E':
        return 'Kritis';
      default:
        return 'Belum Dinilai';
    }
  }

  String get advice {
    if (score >= 85) return 'Keuangan Anda sangat sehat, pertahankan!';
    if (score >= 70) return 'Cukup baik, tingkatkan rasio tabungan.';
    if (score >= 55) return 'Kurangi pengeluaran tidak perlu.';
    if (score >= 40) return 'Segera evaluasi anggaran bulanan.';
    return 'Butuh perbaikan serius, konsultasi disarankan.';
  }
}

FinancialHealthScore calculateFinancialHealth({
  required double totalIncome,
  required double totalExpenses,
  required double totalSavings,
  required int budgetsHit,
  required int totalBudgets,
  required List<double> monthlyIncomes,
}) {
  final savingsRatio = totalIncome > 0 ? totalSavings / totalIncome : 0.0;
  final expenseToIncomeRatio = totalIncome > 0 ? totalExpenses / totalIncome : 1.0;

  // Income stability: coefficient of variation (lower = more stable)
  double incomeStability = 1;
  if (monthlyIncomes.length >= 3) {
    final mean = monthlyIncomes.reduce((a, b) => a + b) / monthlyIncomes.length;
    if (mean > 0) {
      final variance = monthlyIncomes
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          monthlyIncomes.length;
      final stdDev = sqrt(variance);
      incomeStability = 1 - (stdDev / mean).clamp(0, 1);
    }
  }

  // Scoring (0-100)
  int score = 0;

  // 1. Savings ratio (30 pts)
  score += (savingsRatio * 30).round().clamp(0, 30);

  // 2. Expense-to-income ratio (25 pts): lower is better
  final expenseScore = ((1 - expenseToIncomeRatio) * 25).round().clamp(0, 25);
  score += expenseScore;

  // 3. Budget adherence (25 pts)
  if (totalBudgets > 0) {
    final hitRate = budgetsHit / totalBudgets;
    score += (hitRate * 25).round().clamp(0, 25);
  } else {
    score += 15;
  }

  // 4. Income stability (20 pts)
  score += (incomeStability * 20).round().clamp(0, 20);

  final grade = _grade(score);

  return FinancialHealthScore(
    score: score,
    grade: grade,
    savingsRatio: savingsRatio,
    expenseToIncomeRatio: expenseToIncomeRatio,
    budgetHitRate: budgetsHit,
    totalBudgets: totalBudgets,
    incomeStability: incomeStability,
  );
}

String _grade(int score) {
  if (score >= 85) return 'A';
  if (score >= 70) return 'B';
  if (score >= 55) return 'C';
  if (score >= 40) return 'D';
  return 'E';
}
