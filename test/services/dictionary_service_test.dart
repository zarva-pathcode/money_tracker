import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/dictionary_service.dart';
import 'package:money_tracker/services/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('DictionaryService', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await DictionaryService.instance.init();
    });

    test('init berhasil load data', () {
      expect(DictionaryService.instance.isLoaded, true);
    });

    test('stopwords terdefinisi', () {
      expect(DictionaryService.instance.isStopword('dan'), true);
      expect(DictionaryService.instance.isStopword('di'), true);
    });

    test('separator terdefinisi', () {
      expect(DictionaryService.instance.isSeparator('dan'), true);
    });

    test('monetary suffix terdefinisi', () {
      expect(DictionaryService.instance.isMonetarySuffix('rb'), true);
      expect(DictionaryService.instance.isMonetarySuffix('k'), true);
      expect(DictionaryService.instance.isMonetarySuffix('juta'), true);
      expect(DictionaryService.instance.isMonetarySuffix('jt'), true);
    });

    test('unit words terdefinisi', () {
      expect(DictionaryService.instance.isUnitWord('pcs'), true);
      expect(DictionaryService.instance.isUnitWord('botol'), true);
    });

    test('expense intent terdeteksi', () {
      expect(DictionaryService.instance.isExpenseIntent('beli'), true);
      expect(DictionaryService.instance.isExpenseIntent('bayar'), true);
    });

    test('income intent terdeteksi', () {
      expect(DictionaryService.instance.isIncomeIntent('gajian'), true);
      expect(DictionaryService.instance.isIncomeIntent('bonus'), true);
    });

    test('inferCategory dengan local corrections (setelah setHiveService)', () {
      // Tanpa local corrections, harus fallback ke dictionary
      final cat = DictionaryService.instance.inferCategory('nasi goreng', 'expense');
      expect(cat, isNot('Lainnya'));
    });

    test('inferCategory dengan kata tidak dikenal — Lainnya', () {
      final cat = DictionaryService.instance.inferCategory('zzzzzzzz', 'expense');
      expect(cat, 'Lainnya');
    });

    test('containsIncomeKeyword — true', () {
      expect(DictionaryService.instance.containsIncomeKeyword('gaji bulanan'), true);
    });

    test('containsIncomeKeyword — false', () {
      expect(DictionaryService.instance.containsIncomeKeyword('beli nasi'), false);
    });

    test('matchIntent expense', () {
      final intent = DictionaryService.instance.matchIntent('beli nasi goreng');
      expect(intent, isNotNull);
    });

    test('matchIntent income', () {
      final intent = DictionaryService.instance.matchIntent('bonus bulan juni');
      expect(intent, isNotNull);
      expect(intent, 'bonus');
    });
  });
}
