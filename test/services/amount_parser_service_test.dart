import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/amount_parser_service.dart';

void main() {
  group('tryParseRaw', () {
    test('angka sederhana', () {
      expect(AmountParserService.tryParseRaw('50000', null), 50000);
    });

    test('angka dengan suffix rb', () {
      expect(AmountParserService.tryParseRaw('25', 'rb'), 25000);
    });

    test('angka dengan suffix k', () {
      expect(AmountParserService.tryParseRaw('10', 'k'), 10000);
    });

    test('angka dengan suffix juta', () {
      expect(AmountParserService.tryParseRaw('1.5', 'jt'), 1500000);
    });

    test('slang goceng', () {
      expect(AmountParserService.tryParseRaw('goceng', null), 5000);
    });

    test('slang cepek', () {
      expect(AmountParserService.tryParseRaw('cepek', null), 100);
    });

    test('slang gopek', () {
      expect(AmountParserService.tryParseRaw('gopek', null), 500);
    });

    test('setengah juta', () {
      expect(AmountParserService.tryParseRaw('setengah juta', null), 500000);
    });

    test('setengah', () {
      expect(AmountParserService.tryParseRaw('setengah', null), 500);
    });

    test('angka dengan separator ribuan', () {
      // "1.500" bisa berarti 1.5 ribu atau 1500 tergantung konteks
      const raw = '1.500';
      final result = AmountParserService.tryParseRaw(raw, null);
      expect(result, 1500);
    });

    test('angka nol atau negatif — null', () {
      expect(AmountParserService.tryParseRaw('0', null), isNull);
      expect(AmountParserService.tryParseRaw('-100', null), isNull);
    });
  });

  group('_resolveAmount', () {
    test('tanpa suffix', () {
      // Via tryParseRaw
      expect(AmountParserService.tryParseRaw('50000', null), 50000);
    });

    test('suffix ribu', () {
      expect(AmountParserService.tryParseRaw('2', 'ribu'), 2000);
    });

    test('suffix rb', () {
      expect(AmountParserService.tryParseRaw('1', 'rb'), 1000);
    });

    test('suffix k', () {
      expect(AmountParserService.tryParseRaw('5', 'k'), 5000);
    });

    test('suffix juta', () {
      expect(AmountParserService.tryParseRaw('3', 'juta'), 3000000);
    });

    test('suffix jt', () {
      expect(AmountParserService.tryParseRaw('2', 'jt'), 2000000);
    });

    test('desimal dengan suffix', () {
      expect(AmountParserService.tryParseRaw('0.5', 'jt'), 500000);
      expect(AmountParserService.tryParseRaw('1.5', 'rb'), 1500);
    });
  });

  group('_normalizeNumber', () {
    test('cleanup koma ribuan', () {
      // 1,500,000 → 1500000
      const raw = '1,500,000';
      // Ini dipanggil melalui tryParseRaw
      final result = AmountParserService.tryParseRaw(raw, null);
      expect(result, 1500000);
    });

    test('dot ribuan case: 1.500', () {
      // 1.500 → 1500 (diproses oleh _dotThousand)
      final result = AmountParserService.tryParseRaw('1.500', null);
      expect(result, 1500);
    });
  });

  group('findAllMonetarySpans', () {
    test('angka dalam teks', () {
      final spans = AmountParserService.findAllMonetarySpans('beli nasi 25000');
      expect(spans.length, 1);
      expect(spans.first.rawText, '25000');
    });

    test('multiple angka', () {
      final spans = AmountParserService.findAllMonetarySpans('10000 dan 5000');
      expect(spans.length, 2);
      expect(spans[0].rawText, '10000');
      expect(spans[1].rawText, '5000');
    });

    test('angka dengan suffix', () {
      final spans = AmountParserService.findAllMonetarySpans('2rb');
      expect(spans.length, 1);
      expect(spans.first.rawText, '2');
      expect(spans.first.monetarySuffix, 'rb');
    });

    test('slang terdeteksi', () {
      final spans = AmountParserService.findAllMonetarySpans('goceng');
      expect(spans.any((s) => s.rawText == 'goceng'), true);
    });

    test('teks tanpa angka — kosong', () {
      final spans = AmountParserService.findAllMonetarySpans('halo dunia');
      expect(spans, isEmpty);
    });
  });

  group('_slangValue', () {
    test('seceng', () {
      expect(AmountParserService.tryParseRaw('seceng', null), 1000);
    });

    test('noceng', () {
      expect(AmountParserService.tryParseRaw('noceng', null), 2000);
    });

    test('ceban', () {
      expect(AmountParserService.tryParseRaw('ceban', null), 10000);
    });

    test('noban', () {
      expect(AmountParserService.tryParseRaw('noban', null), 20000);
    });

    test('goban', () {
      expect(AmountParserService.tryParseRaw('goban', null), 50000);
    });

    test('unknown slang', () {
      expect(AmountParserService.tryParseRaw('unknown', null), isNull);
    });
  });

  group('extractRightmost (angka >= 1000)', () {
    test('ekstrak angka kanan', () {
      final result = AmountParserService.extractRightmost('beli nasi 25000');
      expect(result.amount, 25000);
      expect(result.remaining, 'beli nasi');
    });

    test('dua angka — ambil paling kanan', () {
      final result = AmountParserService.extractRightmost('10000 dan 5000');
      expect(result.amount, 5000);
      expect(result.remaining, '10000 dan');
    });

    test('angka dengan suffix rb', () {
      final result = AmountParserService.extractRightmost('beli 2rb');
      expect(result.amount, 2000);
      expect(result.remaining, 'beli');
    });

    test('teks tanpa angka — null', () {
      final result = AmountParserService.extractRightmost('halo dunia');
      expect(result.amount, isNull);
    });

    test('teks kosong — null', () {
      final result = AmountParserService.extractRightmost('');
      expect(result.amount, isNull);
    });
  });
}
