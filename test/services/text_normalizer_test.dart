import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/text_normalizer.dart';

void main() {
  group('normalizeTitle', () {
    test('lowercase dan trim', () {
      expect(normalizeTitle('  GO-JEK  '), 'gojek');
    });

    test('collapse spasi', () {
      expect(normalizeTitle('beli   baju'), 'beli baju');
    });

    test('hapus repeated chars >2', () {
      expect(normalizeTitle('makanannn enak'), 'makanan enak');
    });

    test('hapus non-alphanumeric di tepi', () {
      expect(normalizeTitle('!!pulsa!!'), 'pulsa');
    });
  });

  group('levenshteinDistance', () {
    test('string identik — 0', () {
      expect(levenshteinDistance('abc', 'abc'), 0);
    });

    test('string kosong — length', () {
      expect(levenshteinDistance('', 'abc'), 3);
      expect(levenshteinDistance('abc', ''), 3);
    });

    test('satu karakter beda — 1', () {
      expect(levenshteinDistance('abc', 'abd'), 1);
    });

    test('completely berbeda', () {
      expect(levenshteinDistance('abc', 'xyz'), 3);
    });
  });

  group('similarity', () {
    test('identik — 1.0', () {
      expect(similarity('abc', 'abc'), 1.0);
    });

    test('kosong — 1.0', () {
      expect(similarity('', ''), 1.0);
    });

    test('satu karakter beda — sekitar 0.67', () {
      final sim = similarity('abc', 'abd');
      expect(sim, greaterThan(0.6));
      expect(sim, lessThan(0.7));
    });
  });

  group('findClosestMatch', () {
    test('cocok dengan threshold default', () {
      final result = findClosestMatch('gojek', ['gojek indonesia', 'grab', 'shopee']);
      expect(result, 'gojek indonesia');
    });

    test('tidak cocok — return null', () {
      final result = findClosestMatch('abcdefgh', ['gojek', 'grab']);
      expect(result, isNull);
    });

    test('threshold lebih ketat', () {
      final result = findClosestMatch('abc', ['abcdef'], threshold: 0.95);
      expect(result, isNull);
    });

    test('input kosong — return null', () {
      expect(findClosestMatch('', ['a', 'b']), isNull);
    });
  });
}
