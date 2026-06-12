import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/transaction_parser_service.dart';
import 'package:money_tracker/services/dictionary_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DictionaryService.instance.init();
  });

  group('TransactionParserService.parse', () {
    test('input kosong — return []', () {
      expect(TransactionParserService.parse(''), isEmpty);
      expect(TransactionParserService.parse('   '), isEmpty);
    });

    test('expense sederhana: "beli nasi 15000"', () {
      final result = TransactionParserService.parse('beli nasi 15000');
      expect(result.length, 1);
      expect(result.first.type, 'expense');
      expect(result.first.amount, 15000);
    });

    test('income: "gajian 5000000"', () {
      final result = TransactionParserService.parse('gajian 5000000');
      expect(result.length, 1);
      expect(result.first.type, 'income');
      expect(result.first.amount, 5000000);
    });

    test('multi transaksi: "beli nasi 15000 dan kopi 5000"', () {
      final result = TransactionParserService.parse('beli nasi 15000 dan kopi 5000');
      expect(result.length, 1);
      expect(result.first.amount, 20000);
    });

    test('angka dengan suffix rb', () {
      final result = TransactionParserService.parse('beli baju 50rb');
      expect(result.length, 1);
      expect(result.first.amount, 50000);
    });

    test('angka dengan suffix ribu', () {
      final result = TransactionParserService.parse('beli sembako 100 ribu');
      expect(result.length, 1);
      expect(result.first.amount, 100000);
    });

    test('teks tanpa angka — return []', () {
      final result = TransactionParserService.parse('beli nasi goreng');
      expect(result, isEmpty);
    });
  });
}
