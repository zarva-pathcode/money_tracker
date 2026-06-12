import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/text_parser_service.dart';
import 'package:money_tracker/services/dictionary_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DictionaryService.instance.init();
  });

  group('TextParserService.removeStopwords', () {
    test('hapus stopwords dasar', () {
      final result = TextParserService.removeStopwords('beli nasi dan ayam');
      expect(result, 'nasi ayam');
    });

    test('hapus stopwords di awal', () {
      final result = TextParserService.removeStopwords('saya mau beli baju');
      expect(result, 'baju');
    });

    test('teks tanpa stopwords — tetap', () {
      final result = TextParserService.removeStopwords('nasi goreng ayam');
      expect(result, 'nasi goreng ayam');
    });

    test('semua stopwords — empty', () {
      final result = TextParserService.removeStopwords('dan atau dan');
      expect(result, '');
    });

    test('string kosong', () {
      expect(TextParserService.removeStopwords(''), '');
    });
  });
}
