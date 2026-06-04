import '../models/expense.dart';
import '../services/transaction_parser_service.dart';

class VoiceTransactionService {
  static double calculateNetExpense(List<ParsedTransaction> results) {
    final totalNewExpense = results
        .where((r) => r.type == 'expense' && r.amount > 0)
        .fold<double>(0, (sum, r) => sum + r.amount);
    final totalNewIncome = results
        .where((r) => r.type == 'income' && r.amount > 0)
        .fold<double>(0, (sum, r) => sum + r.amount);
    return (totalNewExpense - totalNewIncome).clamp(0.0, double.infinity);
  }

  static List<Expense> buildExpenses(List<ParsedTransaction> results) {
    final expenses = <Expense>[];
    int i = 0;
    for (final r in results) {
      if (r.amount <= 0) continue;
      expenses.add(Expense(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        title: r.description,
        amount: r.amount.toDouble(),
        date: DateTime.now(),
        category: r.category,
        type: r.type,
      ));
      i++;
    }
    return expenses;
  }
}
