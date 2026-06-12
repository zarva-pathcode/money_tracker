import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/voice_transaction_service.dart';
import 'package:money_tracker/services/transaction_parser_service.dart';

void main() {
  group('VoiceTransactionService.calculateNetExpense', () {
    test('semua expense — total expense', () {
      final results = [
        ParsedTransaction(type: 'expense', description: 'Nasi', amount: 15000),
        ParsedTransaction(type: 'expense', description: 'Kopi', amount: 5000),
      ];
      expect(VoiceTransactionService.calculateNetExpense(results), 20000);
    });

    test('campur income + expense — net expense', () {
      final results = [
        ParsedTransaction(type: 'expense', description: 'Beli Baju', amount: 50000),
        ParsedTransaction(type: 'income', description: 'Gaji', amount: 100000),
      ];
      expect(VoiceTransactionService.calculateNetExpense(results), 0);
    });

    test('hanya income — 0', () {
      final results = [
        ParsedTransaction(type: 'income', description: 'Bonus', amount: 200000),
      ];
      expect(VoiceTransactionService.calculateNetExpense(results), 0);
    });

    test('list kosong — 0', () {
      expect(VoiceTransactionService.calculateNetExpense([]), 0);
    });
  });

  group('VoiceTransactionService.buildExpenses', () {
    test('semua parsed diubah jadi Expense', () {
      final results = [
        ParsedTransaction(type: 'expense', description: 'Nasi Goreng', amount: 25000, category: 'Makanan'),
        ParsedTransaction(type: 'expense', description: 'Es Teh', amount: 5000, category: 'Makanan'),
      ];
      final expenses = VoiceTransactionService.buildExpenses(results);
      expect(expenses.length, 2);
      expect(expenses[0].title, 'Nasi Goreng');
      expect(expenses[0].amount, 25000);
      expect(expenses[1].category, 'Makanan');
    });

    test('amount <= 0 di-skip', () {
      final results = [
        ParsedTransaction(type: 'expense', description: 'Valid', amount: 10000),
        ParsedTransaction(type: 'expense', description: 'Skip', amount: 0),
        ParsedTransaction(type: 'income', description: 'Invalid', amount: -500),
      ];
      final expenses = VoiceTransactionService.buildExpenses(results);
      expect(expenses.length, 1);
      expect(expenses.first.title, 'Valid');
    });

    test('list kosong', () {
      expect(VoiceTransactionService.buildExpenses([]), isEmpty);
    });
  });
}
